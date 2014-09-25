#Note: required by Capfile
class SSHKit::Formatter::Pretty

  def write_command(command)
    unless command.started?
      #yellow --> blue
      original_output << level(command.verbosity) + uuid(command) + "Running #{c.blue(c.bold(String(command)))} on #{c.blue(command.host.to_s)}\n"
      #comment to avoid verbose
      #if SSHKit.config.output_verbosity == Logger::DEBUG
      #  original_output << level(Logger::DEBUG) + uuid(command) + "Command: #{c.blue(command.to_command)}" + "\n"
      #end
    end

    #cmd's stdout and stderr
    if SSHKit.config.output_verbosity == Logger::DEBUG
      unless command.stdout.empty?
        command.stdout.lines.each do |line|
          #fix encoding!
          #original_output << level(Logger::DEBUG) + uuid(command) + c.green("\t" + line)
          original_output << level(Logger::DEBUG) + uuid(command) + c.green("\t" + line.force_encoding('utf-8'))
          original_output << "\n" unless line[-1] == "\n"
        end
      end

      unless command.stderr.empty?
        command.stderr.lines.each do |line|
          #fix encoding!
          #original_output << level(Logger::DEBUG) + uuid(command) + c.red("\t" + line)
          original_output << level(Logger::DEBUG) + uuid(command) + c.red("\t" + line.force_encoding('utf-8'))
          original_output << "\n" unless line[-1] == "\n"
        end
      end
    end

    if command.finished?
      #Customized long runtime yellow warning!
      taken_time = command.runtime
      time_str = sprintf('%5.3f seconds', taken_time)
      if taken_time > 2 
        time_str = c.red(time_str)
      elsif taken_time > 0.5
        time_str = c.yellow(time_str)
      end

      original_output << level(command.verbosity) + uuid(command) + "Finished in #{time_str} with exit status #{command.exit_status} (#{c.bold { command.failure? ? c.red('failed') : c.green('successful') }}).\n"
    end
  end
end
