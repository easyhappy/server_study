class App
  def call(env)
    puts "env is : #{env}"
    if env["PATH_INFO"] == "/sleep"
      sleep 10
      puts 'sleep 10s'
    end
    message = "Hello from the andy, and process pid is : #{Process.pid}\n"
    [200,
      {"Content-Type" => "text/plain"},
      [message]
    ]
  end
end

run App.new
