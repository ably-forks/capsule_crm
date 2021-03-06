module CapsuleCRM
  class Opportunity
    include Virtus.model

    extend  ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    include CapsuleCRM::Associations
    include CapsuleCRM::Inspector
    include CapsuleCRM::Querying::Findable
    include CapsuleCRM::Persistence::Persistable
    include CapsuleCRM::Persistence::Deletable
    include CapsuleCRM::Serializable

    serializable_config do |config|
      config.excluded_keys = [:track_id, :probability]
    end

    queryable_config do |config|
      config.plural = :opportunity
    end

    persistable_config do |config|
      config.create = lambda do |opportunity|
        path = "party/#{opportunity.party.try(:id)}/opportunity"
        path += "?trackId=#{opportunity.track_id}" if opportunity.track_id
        path
      end
    end

    attribute :id, Integer
    attribute :name, String
    attribute :description, String
    attribute :currency
    attribute :value, Float
    attribute :duration_basis
    attribute :duration, Integer
    attribute :milestone_id, Integer
    attribute :expected_close_date, DateTime
    attribute :actual_close_date, DateTime
    attribute :probability, Float
    attribute :owner, String

    attr_accessor :milestone, :owner

    validates :id, numericality: { allow_blank: true }
    validates :name, presence: true
    validates :party, presence: true
    validates :milestone, presence: true

    has_many :tasks
    has_many :histories
    has_many :custom_fields, embedded: true

    belongs_to :party
    belongs_to :milestone
    belongs_to :track

    def milestone=(milestone)
      if milestone.is_a?(String)
        milestone = CapsuleCRM::Milestone.find_by_name(milestone)
      end
      @milestone = milestone
      self.milestone_id = milestone.try(:id)
      self
    end

    def self._for_track(track)
      raise NotImplementedError.new("There is no way to find opportunities by trackId in the Capsule API right now")
    end

    # Public: Get all deleted opportunities since the specified date
    #
    # since - The Date to start checking for deleted opportunities
    #
    # Examples
    #
    # CapsuleCRM::Opportunity.deleted(1.week.ago)
    #
    # Returns a ResultsProxy of opportunities
    def self.deleted(since)
      CapsuleCRM::Normalizer.new(
        self, root: 'deletedOpportunity', collection_root: 'deletedOpportunities'
      ).normalize_collection(
        CapsuleCRM::Connection.get('/api/opportunity/deleted', since: since)
      )
    end

    class << self
      alias :_for_organization :_for_party
      alias :_for_person :_for_party
    end
  end
end
