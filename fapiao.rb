#!/usr/bin/env ruby

target_amount = ARGV.pop || 700

# I download fapiao as PDF files and rename to their amount (e.g. "42.pdf" or
# "168-20.pdf"), so let's convert filename to number.
fapiao_values = Dir.glob('*.pdf')
                  .map { |f| File.basename f, '.pdf' }
                  .map { |s| s.include?('-') ? s.gsub('-', '.').to_f : s.to_i }

# Do I want to use as less fapiao as possible?
less_fapiao = false

# Process data to produce an lp_solve model.
coefficients = fapiao_values.map.with_index { |_, i| "x#{i}" }

fapiao_sum = fapiao_values.zip(coefficients)
                          .map { |pair| pair.join ' ' }
                          .join ' + '

objective = less_fapiao ? "#{fapiao_sum} + #{coefficients.join ' + '}" : fapiao_sum

model = <<~LP_MODEL
  min: #{objective};
  #{fapiao_sum} >= #{target_amount};
  #{coefficients.map { |x| "#{x} <= 1;" }.join("\n")}
  #{coefficients.map { |x| "int #{x};" }.join("\n")}
LP_MODEL

# Call lp_process and solve the model.
require 'open3'
output, error = Open3.capture3('lp_solve', stdin_data: model)
unless error.empty?
  puts error
  exit 1
end

# Skip the first four lines of the lp_solve output and parse the result.
indices = output.split("\n")[4..-1]
                .map(&:split)
                .select { |_, k| k == '1' }
                .map { |x, _| x[1..-1].to_i }
picked_values = fapiao_values.values_at(*indices)

# Mimic the colorize gem
def colorize(color_code, value)
  "\e[#{color_code}m#{value}\e[0m"
end

{
  red: 31,
  green: 32,
  yellow: 33,
  blue: 34,
  pink: 35,
  light_blue: 36
}.each do |color_name, color_code|
  define_method color_name do |value|
    colorize(color_code, value)
  end
end

puts "This is the target amount: #{red(target_amount)}"
puts "These are your fapiao: #{yellow(fapiao_values)}"
puts "This is the actual amount: #{green(picked_values.sum)}"
puts "These are the fapiaos: #{light_blue(picked_values)}"
