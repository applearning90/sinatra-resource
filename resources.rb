require "sinatra"
require "erb"

enable :sessions

use Rack::MethodOverride 

class NameValidator
  def initialize(member, members)
    @member = member.to_s
    @members = members
  end

  def message
    @message
  end

  def valid?
    validate
    @message.nil?
  end

  private

  def validate
    if @member.empty?
      @message = "Please enter a name."
    elsif @members.include?(@member)
      @message = "Member #{@member} has already been registered."
    end
  end
end      

def read_members
  return [] unless File.exist?("members.txt")
  File.read("members.txt").split("\n")
end

def store_member(name)
  File.open("members.txt", "a+") do |file|
    file.puts(name)
  end
end

def update_member(name, new_name)
  #load file as a string
  members = File.read("members.txt")
  # globally substitute new name
  members = members.gsub(name, new_name)
  File.open("members.txt", "w") do |file|
    file.write(members)
  end
end

def delete_member(name)
  members = ''
  File.readlines("members.txt").each do |line|
    p [line, name]
    members += line unless line.chomp.eql?(name)
  end

  members == '' if members == '\n'

  File.open("members.txt", "w") do |file|
    file.puts(members)
  end
end

get "/members" do
  # displays all members
  @members = read_members
  @message = session.delete(:message)
	erb :index
end

get "/members/new" do
  # displays a form to add new member
  erb :new
end

get "/members/:name" do
  # dispays a single member
  @member = params["name"]
  @message = session.delete(:message)
  erb :show
end

post "/members" do
  # creates the new member
  @member = params["name"]
  @members = read_members
  validator = NameValidator.new(@member, @members)

  if validator.valid?
    store_member(@member)
    session[:message] = "Successfully saved new member."
    redirect "/members/#{@member}"
  else
    session[:message] = validator.message
    erb :new
  end
end

get "/members/:name/edit" do
  # displays form for editing a member
  @member = params["name"]
  erb :edit
end

put "/members/:name" do
  # updates member info
  @name = params["name"]
  @new_name = params["new_name"]
  update_member(@name, @new_name)
  session[:message] = "Member info successfully updated"
  redirect "/members/#{ @new_name}"
end

get "/members/:name/delete" do
  # asks for confirmation to delete a member
  @member = params["name"]
  erb :delete
end

delete "/members/:name" do
  # delete a member 
  @member = params["name"]
  delete_member(@member)
  session[:message] = "Member #{:name} successfully deleted."
  redirect "/members"
end