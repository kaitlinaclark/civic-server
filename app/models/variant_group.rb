class VariantGroup < ActiveRecord::Base
  include Moderated
  include Subscribable
  include WithAudits
  include SoftDeletable
  include WithSingleValueAssociations
  acts_as_commentable

  has_many :variant_group_variants
  has_many :variants, through: :variant_group_variants
  has_and_belongs_to_many :sources

  display_by_attribute :variant, :name

  def self.index_scope
    includes(variants: [:gene, :evidence_items_by_status, :variant_types])
  end

  def self.view_scope
    includes(variants: [:gene, :evidence_items_by_status, :variant_types, :variant_groups])
  end

  def self.datatable_scope
    joins(variants: [:gene, :evidence_items])
  end

  def additional_changes_info
    @@additional_variant_group_changes ||= {
      'sources' => {
        output_field_name: 'source_ids',
        query: ->(x) { Source.get_sources_from_list(x.reject(&:blank?)).map(&:id).sort.uniq },
        id_field: 'id'
      },
      'variants' => {
        output_field_name: 'variant_ids',
        query: -> (x) { Variant.find(x.reject(&:blank?)).map(&:id).sort.uniq },
        id_field: 'id',
      }
    }
  end

  def state_params
    gene = self.variants.eager_load(:gene).first.gene
    {
      variant_group: {
        name: self.name,
        id: self.id
      },
      gene: {
        id: gene.id,
        name: gene.name
      }
    }
  end

  def lifecycle_events
    {
      last_modified: :last_applied_change,
      created: :creation_audit
    }
  end
end
