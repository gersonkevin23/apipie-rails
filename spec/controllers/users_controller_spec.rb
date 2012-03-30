require 'spec_helper'

describe UsersController do

  describe "GET show" do

    it "find a user with id" do
      get :show, :id => 5, :session => "secret_hash"
      
      assert_response :success
    end

    it "throw ArgumentError if some required parameter missing" do
      lambda { get :show, :id => 5 }.should raise_error(ArgumentError)
    end
    
    it "responds with status 401 if session is wrong" do
      get :show, :id => 5, :session => "bad_hash"
      assert_response 401
    end

    it "should be annotated" do
      
      a = Restapi.get_method_description(UsersController, :show)
      b = Restapi[UsersController, :show]
      a.should eq(b)

      a.method.should eq(:show)
      a.resource.should eq('users')
      a.errors[0].code.should eq(401)
      a.errors[0].description.should eq("Unauthorized")
      a.errors[1].code.should eq(404)
      a.errors[1].description.should eq("Not Found")

      a.short_description.should eq("Show user profile")
      a.path.should eq("/users/:id")
      a.http.should eq("GET")

      param = a.params[:session]
      param.required.should eq(true)
      param.desc.should eq("user is logged in")
      param.validator.class.should be(Restapi::Validator::TypeValidator)
      param.validator.instance_variable_get("@type").should eq(String)
      
      param = a.params[:float_param]
      param.required.should eq(false)
      param.desc.should eq("float param")
      param.validator.class.should be(Restapi::Validator::TypeValidator)
      param.validator.instance_variable_get("@type").should eq(Float)

      param = a.params[:id]
      param.required.should eq(true)
      param.desc.should eq("user id")
      param.validator.class.should be(Restapi::Validator::TypeValidator)
      param.validator.instance_variable_get("@type").should eq(Integer)

      param = a.params[:regexp_param]
      param.desc.should eq("regexp param")
      param.required.should eq(false)
      param.validator.class.should be(Restapi::Validator::RegexpValidator)
      param.validator.instance_variable_get("@regexp").should eq(/^[0-9]* years/)

      param = a.params[:array_param]
      param.desc.should eq("array validator")
      param.validator.class.should be(Restapi::Validator::ArrayValidator)
      param.validator.instance_variable_get("@array").should eq([100, "one", "two", 1, 2])

      param = a.params[:proc_param]
      param.desc.should eq("proc validator")
      param.validator.class.should be(Restapi::Validator::ProcValidator)
      
      a.full_description.length.should be > 400
    end
    
    it "should yell ArgumentError if id is not a number" do
      lambda { get :show, :id => "not a number", :session => "secret_hash" }.should raise_error(ArgumentError)
    end
    
    it "should yell ArgumentError if float_param is not a float" do
      lambda { get :show, :id => 5, :session => "secret_hash", :float_param => "234.2.34"}.should raise_error(ArgumentError)
      lambda { get :show, :id => 5, :session => "secret_hash", :float_param => "no float here"}.should raise_error(ArgumentError)
    end

    it "should understand float validator" do
      get :show, :id => 5, :session => "secret_hash", :float_param => "234.34"
      assert_response :success
      get :show, :id => 5, :session => "secret_hash", :float_param => "234"
      assert_response :success
    end
    
    it "should understand regexp validator" do
      get :show, :id => 5, :session => "secret_hash", :regexp_param => "24 years"
      assert_response :success
    end
    
    it "should validate with regexp validator" do
      lambda {
        get :show, :id => 5, :session => "secret_hash", :regexp_param => "ten years"
      }.should raise_error(ArgumentError)
    end
    
    it "should validate with array validator" do
      get :show, :id => 5, :session => "secret_hash", :array_param => "one"
      assert_response :success
      get :show, :id => 5, :session => "secret_hash", :array_param => "two"
      assert_response :success
      get :show, :id => 5, :session => "secret_hash", :array_param => 1
      assert_response :success
      get :show, :id => 5, :session => "secret_hash", :array_param => "2"
      assert_response :success
    end
    
    it "should raise ArgumentError with array validator" do
      lambda { get :show, :id => 5, :session => "secret_hash", :array_param => "blabla" }.should
      raise_error(ArgumentError)
      
      lambda { get :show, :id => 5, :session => "secret_hash", :array_param => 3 }.should
      raise_error(ArgumentError)
    end
    
    it "should validate with Proc validator" do
      lambda { get :show, :id => 5, :session => "secret_hash", :proc_param => "asdgsag" }.should
      raise_error(ArgumentError)
      
      get :show, :id => 5, :session => "secret_hash", :proc_param => "param value"
      assert_response :success
    end
    
  end

end
