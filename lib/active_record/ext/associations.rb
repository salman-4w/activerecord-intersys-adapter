# Caché handles foreign keys a little differently, so we extend a few of the
# association class methods to provide sensible defaults.
#
# 1) Foreign keys match the class name that they attach to, sans _id
# 2) Referential integrity is always on, so restrict has_many deletions
module ActiveRecord
  module Associations
    module ClassMethods
      # see lib/active_record/assocations.rb#has_many
      def has_many(name, options={}, &extension)
        options[:foreign_key] ||= self.name.downcase
        options[:dependent]   ||= :restrict
        Builder::HasMany.build(self, name, options, &extension)
      end
      # see lib/active_record/assocations.rb#belongs_to
      def belongs_to(name, options={})
        options[:foreign_key] ||= name
        Builder::BelongsTo.build(self, name, options)
      end
      def has_one(name, options={})
        options[:foreign_key] ||= self.name.downcase
        Builder::HasOne.build(self, name, options)
      end
    end
  end
end
