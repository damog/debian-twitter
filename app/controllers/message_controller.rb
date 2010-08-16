require "pp"

class MessageController < ApplicationController
  protect_from_forgery :except => :new
  
  def new
    if request.method == :get
      resp = 'No GET method supported.'
    else
      post_data = request.body.read
      
      tf_data     = Tempfile.open('microb_postdata')
      tf_stdout   = Tempfile.open('microb_stdout')
      tf_stderr   = Tempfile.open('microb_stderr')
      
      tf_data.puts post_data
      tf_data.close
      
      result = system "cat #{tf_data.path} | gpg --keyring /tmp/keys/debian-keyring.gpg --keyring /tmp/keys/debian-maintainers.gpg > #{tf_stdout.path} 2> #{tf_stderr.path}"
      
      if result # ran properly
        tweet = tf_stdout.read.strip
        out = tf_stderr.read
        sig = out.scan(/Signature made.+key ID ([0-9A-F]{8})/)

        fpra = IO.popen("gpg --keyring /tmp/keys/debian-keyring.gpg --keyring /tmp/keys/debian-maintainers.gpg --fingerprint #{sig}").readlines[1].scan(/Key fingerprint = ([A-F0-9 ]{50})/).first.first.gsub(/\s+/, '')

        resp = "About to tweet: #{tweet} with sig: `#{sig}' and fpr = #{fpra.inspect}"
      else
        resp = "Not cool at all."
      end
      
    end
    
    render :text => "#{resp}\n", :content_type => 'text/plain'
  end
  
end
