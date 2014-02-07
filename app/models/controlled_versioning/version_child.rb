module ControlledVersioning
  class VersionChild < ActiveRecord::Base

    belongs_to :versionable, polymorphic: true
    belongs_to :version, polymorphic: true
    has_many :version_attributes, as: :version
    has_many :version_children, as: :version

    def changes
      ChangeTracker.new(self).get_changes
    end
  end
end
