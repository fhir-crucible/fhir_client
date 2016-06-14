class ClientException < Exception

  attr_accessor :reply

  def initialize(message, reply = nil)
    super(message)
    @reply = reply
  end

end
