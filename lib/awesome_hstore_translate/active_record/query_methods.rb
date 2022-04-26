module AwesomeHstoreTranslate
  module ActiveRecord
    module QueryMethods
      def where(*args)
        opts, *rest = args

        if opts.is_a?(Hash)
          query = spawn
          translated_attrs = translated_attributes(opts)
          untranslated_attrs = untranslated_attributes(opts)

          unless untranslated_attrs.empty?
            query.where!(untranslated_attrs, *rest)
          end

          translated_attrs.each do |key, value|
            if value.is_a?(String)
              query.where!(":value = any(avals(#{key}))", value: value)
            else
              super
            end
          end

          query
        else
          super
        end
      end

      def order(*args)
        if args.is_a?(Array)
          check_if_method_has_arguments!(:order, args)
          query = spawn
          attrs = args
          opts, *_rest = args

          return super if opts.is_a?(String)

          case opts
          when Hash
            attrs = opts
          when Symbol
            attrs = args.index_with { :asc }
          end

          translated_attrs = translated_attributes(attrs)
          untranslated_attrs = untranslated_attributes(attrs)

          unless untranslated_attrs.empty?
            query.order!(untranslated_attrs)
          end

          translated_attrs.each do |key, value|
            query.order!(Arel.sql("#{key} -> '#{I18n.locale}' #{value}"))
          end

          query
        else
          super
        end
      end

      private

      def translated_attributes(opts)
        opts.select{ |key, _| self.translated_attribute_names.include?(key) }
      end

      def untranslated_attributes(opts)
        return safe_untranslated_attributes(opts) if opts.is_a?(Array)

        opts.reject{ |key, _| self.translated_attribute_names.include?(key) }
      end

      def safe_untranslated_attributes(opts)
        opts
          .reject { |opt| opt.is_a?(Arel::Nodes::Ordering) }
          .map! { |opt| Arel.sql(opt.to_s) }
      end
    end
  end
end
