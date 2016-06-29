class Source < ActiveRecord::Base
  include WithTimepointCounts

  has_many :evidence_items
  has_and_belongs_to_many :genes

  after_create :populate_citation_if_needed

  def name
    "#{description} (Pubmed: #{pubmed_id})"
  end

  def display_name
    name
  end

  def self.get_sources_from_list(pubmed_ids)
    pubmed_ids.map do |pubmed_id|
      if (source = Source.find_by(pubmed_id: pubmed_id))
        source
      elsif (citation = Scrapers::PubMed.get_citation_from_pubmed_id(pubmed_id))
        Source.create(pubmed_id: pubmed_id, description: citation)
      else
        raise ListMembersNotFoundError.new(pubmed_ids)
      end
    end
  end

  private
  def populate_citation_if_needed
    unless self.description
      FetchSourceCitation.perform_later(self)
    end
  end
end
