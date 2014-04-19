module Picturefill
  module ViewHelper
    def imgset_tag src, srcset = nil, options = {}
      options.merge!(:src => src)
      options.merge!(:srcset => srcset) if srcset
      content_tag :img, nil, options
    end
    alias_method :imageset_tag, :imgset_tag

    def picture_tag alt = nil
      options = {}
      options.merge alt: alt if alt
      content_tag :picture, nil, options
    end

    def source_tag src, *args
      options = args.extract_options!
      media = args.first.to_s if args.first.kind_of?(String) || args.first.kind_of?(Fixnum)      
      picture_src src, media, options.merge(tag: :source)
    end

    def picturefill uploader, options = {}, &block
      opts = {}
      alt = options.delete :alt
      clazz = options.delete :class
      opts.merge! :"data-alt" => alt unless alt.blank?
      opts.merge! "class" => clazz unless clazz.blank?
      opts.merge! :"data-picture" => true

      if block_given?
        content_tag :div, opts, &block
      else
        content_tag :div, opts, false do
          content = ''
          sizes = options[:sizes] || Picturefill.options[:sizes]
          sizes.map do |size, params|
            if uploader.respond_to?(size)
              content << uploader_picture_src( uploader.send(size), params )
            end
          end
          content << picture_fallback( uploader.send(Picturefill.options[:fallback]), alt: alt )
          content.html_safe
        end
      end
    end

    # simplified version uses a Carrierwave uploader object and our configured options
    def uploader_picture_src uploader, options
      return unless uploader.kind_of?(CarrierWave::Uploader::Base)

      tag = options.delete(:tag) || :div
      ratio_opt = options.delete(:ratio)
      if (val = options.delete(:min_width))
        media_opt = "(min-width: #{val}px)"
      end

      ratio = Picturefill::ViewHelper.ratio_attribute(ratio_opt) unless ratio_opt.blank?
      media_opt = [media_opt, ratio].compact.join(' and ')

      options.merge! :"data-media" => media_opt unless media_opt.blank?
      options.merge! :"data-src" => uploader.url      

      content_tag(tag, nil, options)
    end

    # UGLY AS HELL!!! Needs refactor :P
    def picture_src src, *args
      options = args.extract_options!
      media = args.first.to_s if args.first.kind_of?(String) || args.first.kind_of?(Fixnum)

      tag = options[:tag] || :div
      ratio_opt = options.delete(:ratio).to_i
      media_opt = Picturefill::ViewHelper.extract media unless media.blank? 

      unless media_opt && media_opt =~ /min-device-pixel-ratio/
        # use filename to provide ratio_opt
        filename = Picturefill::ViewHelper.filename(src).first
        fn = filename =~ /_x\d(\d)?/
        if fn && !ratio_opt
          ratio_opt = filename.match(/x\d(\d)?$/).to_s
        else
          auto_ratio_tag = ratio_opt[0] == 'x' unless ratio_opt.blank?
        end
        ratio = Picturefill::ViewHelper.ratio_attribute(ratio_opt) unless ratio_opt.blank?
        media_opt = [media_opt, ratio].compact.join(' and ')
      end
      
      next_content = if auto_ratio_tag
        opts = options.dup
        filename = Picturefill::ViewHelper.ratio_file_name src, ratio_opt
        opts.merge!(:ratio => ratio_opt.delete('x'))
        picture_src filename, media, opts
      end

      options.merge! :"data-media" => media_opt unless auto_ratio_tag || media_opt.blank?
      options.merge! :"data-src" => src      

      content_tag(tag, nil, options) + next_content
    end

    def picture_fallback src, options = {}
      content_tag :noscript, content_tag(:img, nil, options.merge(src: src))
    end

    class << self
      def filename src
        src_parts = src.split('.')
        ext = src_parts[1..-1].join('.')
        [src_parts.first, ext]
      end

      def ratio_file_name src, ratio_opt
        fn_parts = filename(src)
        ratio_opt = ratio_opt.delete('x')
        "#{fn_parts.first}_x2.#{fn_parts.last}"
      end

      def extract media
        return if media.blank?
        case media 
        when /^(\d+)$/
          "(min-width: #{media}px)"
        when /^(\d+)px$/
          "(min-width: #{media})"
        when /min-width: (\d+)$/
          "(#{media}px)"
        when /min-width: (\d+)px$/
          "(#{media})"
        else 
          raise ArgumentError, "Picturefill :media attribute could not be parsed, was: #{media}"
        end
      end

      def ratio_attribute ratio
        dpi = 96 * ratio
        out=<<-END
        (-webkit-min-device-pixel-ratio: #{ratio}),
        (min--moz-device-pixel-ratio: #{ratio}),
        (min-device-pixel-ratio:  #{ratio}),
        (min-resolution: #{dpi}dpi),
        (min-resolution: #{ratio}dppx)
        END
        out.strip
      end
    end # class methods
  end
end