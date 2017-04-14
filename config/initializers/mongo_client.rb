class MONGODB
  cattr_accessor :client, :ds  
  host = "#{ENV['OC_MONGO_IP']}:#{ENV['OC_MONGO_PORT']}"
  u = ENV['OC_DS_USER']
  p = ENV['OC_MONGO_PWD']
  @dsadmin = ENV['OC_MONGO_COLLECTION']
  @@ds = ENV['OC_MONGO_DS']

  @@client = Mongo::Client.new([ host ], :database=>ds, :user=>u, :password=>p)
  @db = @@client.database

  def self.collections
    @db.collection_names
  end

  def self.dsadmin
    @db.collection(@dsadmin)
  end

  def self.insert(doc)
    if !doc.is_a? Hash
      raise "document is not a Hash object. You sent me: #{doc.class}"
    end
    c = self.dsadmin
    result = c.insert(doc)
    puts result
    result
  end
end