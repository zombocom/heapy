Then(/^show me the results$/) do
  puts all_output
end

Then(/^it should produce the following output.*:$/) do |table|
  # table is a Cucumber::MultilineArgument::DataTable

  lines = table.raw.flatten.reject(&:empty?)
  lines.each do |line|
    all_output = all_commands.map { |c| c.output }.join("\n")
    expect(all_output).to match(line)
  end
end
