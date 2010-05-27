require 'digest/sha1'

module SimpleCaptcha #:nodoc
  module ViewHelper #:nodoc

    # Simple Captcha is a very simplified captcha.
    #
    # It can be used as a *Model* or a *Controller* based Captcha depending on what options
    # we are passing to the method show_simple_captcha.
    #
    # *show_simple_captcha* method will return the image, the label and the text box.
    # This method should be called from the view within your form as...
    #
    # <%= show_simple_captcha %>
    #
    # The available options to pass to this method are
    # * label
    # * image_syle
    # * object
    # * distortion
    #
    # <b>Label:</b>
    #
    # default label is "type the text from the image", it can be modified by passing :label as
    #
    # <%= show_simple_captcha(:label => "new captcha label") %>.
    #
    # <b>Image Style:</b>
    #
    # There are eight different styles of images available as...
    # * embosed_silver
    # * simply_red
    # * simply_green
    # * simply_blue
    # * distorted_black
    # * all_black
    # * charcoal_grey
    # * almost_invisible
    #
    # The default image is simply_blue and can be modified by passing any of the above style as...
    #
    # <%= show_simple_captcha(:image_style => "simply_red") %>
    #
    # The images can also be selected randomly by using *random* in the image_style as
    # 
    # <%= show_simple_captcha(:image_style => "random") %>
    #
    # *Object*
    #
    # This option is needed to create a model based captcha.
    # If this option is not provided, the captcha will be controller based and
    # should be checked in controller's action just by calling the method simple_captcha_valid?
    #
    # To make a model based captcha give this option as...
    #
    # <%= show_simple_captcha(:object => "user") %>
    # and also call the method apply_simple_captcha in the model
    # this will consider "user" as the object of the model class.
    #
    # *Examples*
    # * controller based
    # <%= show_simple_captcha(:image_style => "embosed_silver", :label => "Human Authentication: type the text from image above") %>
    # * model based
    # <%= show_simple_captcha(:object => "person", :image_style => "simply_blue", :label => "Human Authentication: type the text from image above") %>
    #
    # Find more detailed examples with sample images here on my blog http://EXPRESSICA.com
    #
    # All Feedbacks/CommentS/Issues/Queries are welcome.
    def show_simple_captcha(options={})
      options[:field_value] = set_simple_captcha_data(options)
      
      defaults = {
         :image => simple_captcha_image(options),
         :label => options[:label] || "(type the code from the image)",
         :field => simple_captcha_field(options)
         }
         
      render :partial => 'simple_captcha/simple_captcha', :locals => { :simple_captcha_options => defaults }
    end

    private

      def simple_captcha_image(options={})
        defaults = {}
        defaults[:distortion] = options[:distortion] || 'low'
        defaults[:image_style] = options[:image_style] || 'simply_blue'
        defaults[:time] = options[:time] || Time.now.to_i        
        defaults[:simple_captcha_key] ||= simple_captcha_key(options[:object])
        
        query = defaults.collect{ |key, value| "#{key}=#{value}" }.join('&')
        url = "/simple_captcha?#{query}"
        
        "<img src='#{url}' alt='captcha' />".html_safe
      end
      
      def simple_captcha_field(options={})
        if options[:object]
          #text_field(options[:object], :captcha, :value => '') +
          #hidden_field(options[:object], :captcha_key, {:value => options[:field_value]})
          text_field(:captcha, :value => '') +
          hidden_field(:captcha_key, {:value => options[:field_value]})
        else
          text_field_tag(:captcha)
        end
      end

      def set_simple_captcha_data(options={})
        code_type, object = options[:code_type], options[:object]
        
        key, value = simple_captcha_key(object), generate_simple_captcha_data(code_type)
        data = SimpleCaptchaData.get_data(key)
        data.value = value
        data.save
        key
      end
   
      def generate_simple_captcha_data(code)
        value = ''
        
        case code
          when 'numeric' then 
            SimpleCaptcha.length.times{value << (48 + rand(10)).chr}
          else
            SimpleCaptcha.length.times{value << (65 + rand(26)).chr}
        end
        
        return value
      end
      
      def simple_captcha_key(key_name = nil)
        captcha_key = key_name.nil? ? "captcha" : "captcha_#{key_name}"
        session[captcha_key] ||= Digest::SHA1.hexdigest([Time.now.to_s, session[:id].to_s, captcha_key].join)
      end 
  end
end