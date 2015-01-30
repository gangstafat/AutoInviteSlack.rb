require 'rubygems'
require 'mechanize'
require 'json'
require 'curb'
# require 'pry'

class SlackUserSignup

  #Thông tin cần để truy cập Typeform
  FORM_API_KEY = "YOUR_TYPEFORM_API"
  FORM_ID = "YOUR_TYPEFORM_ID"
  FORM_NAME_FIELD = "YOUR_TYPEFORM_NAME_FIELD"
  FORM_EMAIL_FIELD = "YOUR_TYPEFORM_EMAIL_FIELD"
  #Thông tin cần để truy cập Slack
  SLACK_HOSTNAME = "YOUR_SLACK_TEAM"
  INVITE_CHANNELS = "CHANNELS_ID"
  SLACK_TOKEN = "YOUR_SLACK_TOKEN"
  #Tên file lưu danh sách emails chưa mời 
  UN_INVITED_EMAILS = "UnInvitedEmails.json"
  #Tên file lưu danh sách emails đã mời 
  INVITED_EMAILS = "InvitedEmails.json"

  def initialize

    if File.stat(INVITED_EMAILS).file? 
      @offset = File.foreach(INVITED_EMAILS).count
    else
      @offset = 0
    end

    @agent = Mechanize.new
    @typeform_api_url = "https://api.typeform.com/v0/form/#{FORM_ID}?key=#{FORM_API_KEY}&completed=true&offset=#{@offset}"
    @typeform_data = JSON.parse(@agent.get(@typeform_api_url).body)

  end

  def mails
    @users = Hash.new
    @typeform_data['responses'].each do |item|
      @users[item['answers'][FORM_NAME_FIELD].encode("UTF-8")] = item['answers'][FORM_EMAIL_FIELD]
    end
  end

  def invite

    @invited_users = Hash.new

    invited_list = File.open(INVITED_EMAILS, "a")
    failed_to_invite_list = File.open(UN_INVITED_EMAILS,"a")

    @time = Time.now.to_i
    @slack_invite_url = "https://#{SLACK_HOSTNAME}.slack.com/api/users.admin.invite?t=#{@time}"
    c = Curl::Easy.new(@slack_invite_url)
    @users.each do |key,value|
      puts "Đang mời #{key} <#{value}>"
      if (c.http_post(
        Curl::PostField.content('token', SLACK_TOKEN),
        Curl::PostField.content('firstname', key),
        Curl::PostField.content('email', value),
        Curl::PostField.content('chanels', INVITE_CHANNELS),
        Curl::PostField.content('set_active', true),
        Curl::PostField.content('_attempt', 1)
        ))
        puts "Đã mời"
        invited_list.write(value + "\n")
        @invited_users[key] = @invited_users[value]
      else
        puts "Có lỗi, không mời được"
        failed_to_invite_list.write(value + "\n")
      end
    end
  end

end


Test = SlackUserSignup.new
Test.mails
Test.invite
