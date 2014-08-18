class Revision::Factory < Revision

  attr_reader :versionable, :suggested_attributes
  attr_accessor :version
  def initialize(args)
    @versionable = args[:versionable]
    @version = args[:version]
    @suggested_attributes = args[:suggested_attributes]
  end

  def build
    versionable.assign_attributes(suggested_attributes)
    versionable.valid?
    validate_presence_of_changes
    versionable.errors.present? ? versionable : build_parent
  end

  def build_associations
    mark_for_removal
    build_attributes
    build_children
  end

  private
  def validate_presence_of_changes
    unless Revision::Auditor.new(versionable).changes_original?
      versionable.errors[:base] << I18n.t("errors.messages.no_revisions_made")
    end
  end

  def build_parent
    self.version = versionable.versions.build
    version.notes = versionable_notes
    version.user = versionable_user
    build_associations
    version.save
    version
  end

  def mark_for_removal
    version.marked_for_removal = true if versionable.marked_for_destruction?
  end

  def build_attributes
    versionable_attributes.each do |attr|
      attr = AttributeEncapsulator.new(attr)
      if versionable_changed_attributes.include?(attr.key)
        build_attribute(attr)
      end
    end
  end

  def build_attribute(attr)
    # return build_text_attributes(attr) if attr_is_text?(attr)
    version_attributes.build(
      name: attr.key,
      new_value: attr.value,
      old_value: previous_value(attr.key))
  end

  def build_text_attributes(attr)
    version_attribute = version_attributes.build(
      name: attr.key,
      old_value: previous_value(attr.key))
    Revision::TextAttribute::Factory.new(
      version: version,
      attr: attr,
      version_attribute: version_attribute
    ).build
  end

  def attr_is_text?(attr)
    versionable.class.columns_hash[attr.key].type == :text
  end

  def build_children
    versionable_nested_associations.each do |association|
      versionable.public_send(association).each do |child|
        build_child(child, association)
      end
    end
  end

  def build_child(child, association)
    if Revision::Auditor.new(child).changes_original?
      version_child = build_version_child(child, association)
      Revision::Factory.new(
        versionable: child,
        version: version_child
      ).build_associations
    end
  end

  def build_version_child(child, association)
    version_child = version_children.build(association_name: association)
    version_child.versionable = child unless child.new_record?
    version_child
  end

end