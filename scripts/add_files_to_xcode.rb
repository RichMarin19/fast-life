#!/usr/bin/env ruby
require 'xcodeproj'

# Open the Xcode project
project_path = 'FastingTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'FastingTracker' }
test_target = project.targets.find { |t| t.name == 'FastingTrackerTests' }

# Get the main group
main_group = project.main_group.find_subpath('FastingTracker', true)
test_group = project.main_group.find_subpath('FastingTrackerTests', true)

# Files to add to main target
main_files = [
  'FastingTracker/QueryIntent.swift',
  'FastingTracker/QueryClassifier.swift',
  'FastingTracker/HealthDataAnalyzer.swift',
  'FastingTracker/ResponseGenerator.swift'
]

# Files to add to test target
test_files = [
  'FastingTrackerTests/QueryClassifierTests.swift'
]

# Add main files
main_files.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in project
  existing_file = main_group.files.find { |f| f.path == file_name }
  next if existing_file

  # Add file reference
  file_ref = main_group.new_reference(file_path)

  # Add to compile sources build phase
  main_target.add_file_references([file_ref])

  puts "✅ Added #{file_name} to FastingTracker target"
end

# Add test files
test_files.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in project
  existing_file = test_group.files.find { |f| f.path == file_name }
  next if existing_file

  # Add file reference
  file_ref = test_group.new_reference(file_path)

  # Add to compile sources build phase
  test_target.add_file_references([file_ref])

  puts "✅ Added #{file_name} to FastingTrackerTests target"
end

# Save the project
project.save

puts "\n🎉 All files added to Xcode project successfully!"
