module Ripple
  module Document
    module Finders
      module ClassMethods
        def find_by(key, query)
          find(find_keys_by(key, query)).compact
        end

        def find_keys_by(key, query)
          if key == "$key" || key == "$bucket"
            index_key = key
          elsif index = indexes[key]
            index_key = index.index_key
          else
            return []
          end
          if query.is_a?(Range) && query.begin == query.end
            query = query.begin
          end
          bucket.get_index(index_key, query)
        end
      end
    end

    module BucketAccess
      alias_method :original_bucket_name, :bucket_name
      def bucket_name
        mt_bucket_name = original_bucket_name
        prefixed_already = mt_bucket_name.match Ripple.config[:namespace] if Ripple.config[:namespace] != nil
        if Ripple.config[:namespace].is_a?(String) and not prefixed_already
          Ripple.config[:namespace] + mt_bucket_name
        else
          mt_bucket_name
        end
      end
    end
  end
end
