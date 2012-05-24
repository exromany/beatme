require 'json'
class Socket

  @@users = Set.new
  @@table = nil

  def initialize ws
    @ws = ws
    @@table = BeatMe::Table.new unless @@table
    @@users << self
    self.onopen(ws.protocol)
    ws.onmessage = lambda do |event|
      self.onmessage(event.data) if event.data.is_a?(String)
    end
    ws.onclose = lambda { |event| self.onclose }
  end

  def send data
    @ws.send data
  end

  def close code = nil, reason = nil
    @ws.close code, reason
  end

  def onopen protocol
    p [:connected, protocol]
    send ({table: @@table.to_hash}.to_json)
    @@users.each {|u| u.send "+1 joined" }
  end

  def onmessage data
    p [:received, data]
    @@users.each {|u| u.send "Someone say: #{data}" }
  end

  def onclose
    p [:closed]
    @@users.delete self
    @@users.each {|u| u.send "-1 :(" }
    @ws = nil
  end

end
