#!/usr/bin/ruby
# A nutty little script to convert upstream names to
# product names on the fly.
# 
# USAGE:
#  aeolus_translate.rb INPUT_FILE OUTPUT_FILE
# e.g.,
#  aeolus_translate.rb config/locales/en.yml config/locales/en_product.yml

require 'yaml'

# TODO: Should probably take these as arguments
INPUT	= ARGV[0] || "config/locales/en.yml"
OUTPUT	= ARGV[1] || "config/locales/en_product.yml"

# You know, this makes it pretty clear what the differences are.
# [!_\:] is an ugly hack to not update YAML keys where it's a risk
SUBS = {
 "Aeolus Conductor" => "CloudForms Cloud Engine",
 "a Deployment" => "an Application",
 "Deployment" => "Application",
 "Pool" => "Cloud Resource Zone",
 "Provider" => "Cloud Resource Provider",
 "Cloud Cloud" => "Cloud",
 "Frontend Realm" => "Cloud Resource Cluster",
 "Hardware Profile" => "Cloud Resource Profile",
 "Assembly" => "Component Blueprint",
 "Assemblies" => "Component Blueprints",
 "Image Template" => "Component Outline",
 "deployment[!_\:]" => "application",
 "Deployable" => "Application Blueprint",
 "deployable[!_\:]" => "application blueprint",
 "Image ID" => "Component Outline ID", # We can't just s/Image/Component Outline/
 "Environment" => "Cloud",
 "Frontend Realm" => " Cloud Resource Cluster"
}

contents = File.read(INPUT)

puts "Read #{contents.size} characters from #{INPUT}"

# Should we just pull the [!_\:] down here?
SUBS.each do |old,new|
  contents.gsub!(old, new)
end

puts "Writing modified version to #{OUTPUT}"
puts " Try 'diff #{INPUT} #{OUTPUT}' to see what changed"

# Write output
outfile = File.open(OUTPUT, 'w')
outfile.write(contents)
