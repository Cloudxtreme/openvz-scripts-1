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
	    @kmemsize = mblf('kmemsize')
	    @lockedpages = mblf('lockedpages')
	    @privvmpages = mblf('privvmpages')
	    @shmpages = mblf('shmpages')
	    @numproc = mblf('numproc')
	    @physpages = mblf('physpages')
	    @vmguarpages = mblf('vmguarpages')
	    @oomguarpages = mblf('oomguarpages')
	    @numtcpsock = mblf('numtcpsock')
	    @numflock = mblf('numflock')
	    @numpty = mblf('numpty')
	    @numsiginfo = mblf('numsiginfo')

	    @tcpsndbuf = mblf('tcpsndbuf')
	    @tcprcvbuf = mblf('tcprcvbuf')
	    @othersockbuf = mblf('othersockbuf')
	    @dgramrcvbuf = mblf('dgramrcvbuf')
	    @numothersock = mblf('numothersock')
	    @dcachesize = mblf('dcachesize')
	    @numfile = mblf('numfile')
	    @numiptent = mblf('numiptent')

	    @diskspace = sh('diskspace')
	    @diskinodes = sh('diskinodes')
	end
	
	def all
	    puts ssh_exec(@status)
	end

	def all
	    puts ssh_exec(@status)
	    puts ssh_exec(@kmemsize)
	    puts ssh_exec(@lockedpages)
	    puts ssh_exec(@privvmpages)
	    puts ssh_exec(@shmpages)
	    puts ssh_exec(@numproc)
	    puts ssh_exec(@physpages)
	    puts ssh_exec(@vmguarpages)
	    puts ssh_exec(@oomguarpages)
	    puts ssh_exec(@numtcpsock)
	    puts ssh_exec(@numflock)
	    puts ssh_exec(@numpty)
	    puts ssh_exec(@numsiginfo)
	    puts ssh_exec(@tcpsndbuf)
	    puts ssh_exec(@tcprcvbuf)
	    puts ssh_exec(@othersockbuf)
	    puts ssh_exec(@dgramrcvbuf)
	    puts ssh_exec(@numothersock)
	    puts ssh_exec(@dcachesize)
	    puts ssh_exec(@numfile)
	    puts ssh_exec(@numiptent)
	    puts ssh_exec(@diskspace)
	    puts ssh_exec(@diskinodes)
	end

	def open_ssh
	    @session = Net::SSH.start(@host, @user)
	end
	
	def close_ssh
	    @session.close
	end

	private
	def ssh_exec(output)
	    stdout = ""
	    @session.exec!("sudo vzlist -a -o #{output}") do |channel, stream, data|
		stdout << data if stream == :stdout
	    end
	    return stdout
	end

	def mblf(value)
	    mblf = ['m', 'b', 'l', 'f']
	    ret = [value]

	    mblf.each do |suffix|
		ret << "#{value}.#{suffix}"
	    end

	    return ret.join(',')
	end
	
	def sh(value)
	    sh = ['s', 'h']
	    ret = [value]

	    sh.each do |suffix|
		ret << "#{value}.#{suffix}"
	    end

	    return ret.join(',')
	end
    end
end
