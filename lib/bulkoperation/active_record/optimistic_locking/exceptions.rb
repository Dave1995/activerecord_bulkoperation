module ActiveRecord

    class NoPersistentRecord < ActiveRecordError
    end

    class NoOrginalRecordFound < ActiveRecordError
    end

    class ExternalDataChange < ActiveRecordError
    end

end
  