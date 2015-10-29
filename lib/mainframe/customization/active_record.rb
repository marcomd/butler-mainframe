# These modules contain extensions for the Host class
module ButlerMainframe
  # This module can be use on rails project.
  #
  # Create a polimorphic model:
  # rails generate screen hook_id:integer 'hook_type:string{30}' 'screen_type:integer{1}' video:text 'message:string{160}' 'cursor_x:integer{1}' 'cursor_y:integer{1}'
  #
  # In the model to be related to screen we insert:
  # has_many :screens, :as => :hook, :dependent => :destroy
  module ActiveRecord
    # screen_type: error, notice, warning...
    def screenshot screen_type, options={}
      options = {
          :message          => nil,
          :video            => nil,
          :rails_model      => Screen
      }.merge(options)
      screen              = options[:rails_model].new
      screen.screen_type  = case screen_type
                              when :notice  then 1
                              when :warning then 2
                              else 0 #error
                            end
      screen.message      = options[:message] || catch_message
      screen.video        = options[:video]   || scan(:y1 => 1, :x1 => 1, :y2 => 22, :x2 => 80)
      screen.cursor_y, screen.cursor_x = get_cursor_axes
      screen
    end
  end
end