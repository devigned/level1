namespace :azure do
  task :create_service_principal do
    File.join(__dir__, '../../scripts/create_service_principal')
  end

  task :provision do

  end
end