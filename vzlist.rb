# This is the "script/library" for the vzlist
#
# Right now will be using net/ssh to connect to the server
# will need to make it more generic for local & remote execution

require 'net/ssh'

module OpenVZ
    class Vzlist
	def initialize(host, user)
	    @host = host
	    @user = user

	    # Define all of the "output format" for each function
	    @status = 'ctid,hostname,status,laverage,cpulimit,cpuunits,ip'
	end

	def status
	    puts ssh_exec(@status)
	end


	private
	def ssh_exec(output)
	    stdout = ""
	    Net::SSH.start(@host, @user) do |ssh|
		# capture only stdout matching a particular pattern
		ssh.exec!("sudo vzlist -a -o #{output}") do |channel, stream, data|
		    stdout << data if stream == :stdout
		end
	    end

	    return stdout
	end
    end
end
