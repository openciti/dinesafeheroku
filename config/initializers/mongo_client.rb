class MONGODB
  def self.client
    host = "#{ENV['OC_MONGO_IP']}:#{ENV['OC_MONGO_PORT']}"
    u = ENV['OC_MONGO_USER']
    p = ENV['OC_MONGO_PASSWORD']
    admin = ENV['OC_MONGO_DB']
    c = ENV['OC_MONGO_COLLECTION']
    db = ENV['OC_MONGO_DS_DB']
    client = Mongo::Client.new([ host ], :database=>db, :user=>u, :password=>p)
    client()
    db = client.database
    db.collection_names
  end 
end