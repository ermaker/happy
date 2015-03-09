module Happy
  module Util
    class Query < Hash
      BASE = {
        body: {
          query: {
            filtered: {
              filter: {
                bool: {
                  must: []
                }
              }
            }
          }
        }
      }

      def initialize
        super
        replace(BASE.deep_dup)
      end

      def match match_
        self[:body][:query][:filtered][:filter][:bool][:must].push(query: { match: match_.deep_dup })
      end

      def range range_
        self[:body][:query][:filtered][:filter][:bool][:must].push(range: range_.deep_dup)
      end

      def exists field
        self[:body][:query][:filtered][:filter][:bool][:must].push(exists: { field: field })
      end

      def sort sort_
        self[:body][:sort] = sort_.deep_dup
      end
    end
  end
end
