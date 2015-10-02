# encoding: UTF-8
def should_support_postgresql_import_functionality
  describe "#supports_imports?" do
    it "should support import" do
      assert ActiveRecord::Base.supports_import?
    end
  end
end
