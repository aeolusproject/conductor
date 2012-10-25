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

# Strings that should never be touched. We change them to a
# placeholder before beginning, and then convert them back at the end.
# This is a little bit of a hack...
EXCEPTIONS = {
 "X-Deltacloud-Provider" => "PLACEHOLDER_XDP",
 "X-Deltacloud-Driver" => "PLACEHOLDER_XDD"
}


# You know, this makes it pretty clear what the differences are.
# [!_\:] is an ugly hack to not update YAML keys where it's a risk
SUBS = {
 "Aeolus Conductor" => "CloudForms Cloud Engine",
 "a Deployment" => "an Application",
 "Deployment" => "Application",
 "Pool" => "Cloud Resource Zone",
 "Provider" => "Cloud Resource Provider",
 "Hardware Profile" => "Cloud Resource Profile",
 "Assembly" => "Component Blueprint",
 "Assemblies" => "Component Blueprints",
 "Image Template" => "Component Outline",
 "deployment[!_\:]" => "application",
 "a Deployable" => "an Application Blueprint",
 "Deployable" => "Application Blueprint",
 "deployable[!_\:]" => "application blueprint",
 "Image ID" => "Component Outline ID", # We can't just s/Image/Component Outline/
 "Environment" => "Cloud",
 "Pool Family" => "Cloud",
 "Realm" => "Cloud Resource Cluster"
}

# These are some special cases where translation goes
# awry and needs to be tweaked. Since hashes are unordered
# in 1.8, we need to do these second, versus just putting
# them at the end...
TWEAKS = {
 "Cloud Cloud" => "Cloud", # BZ 857827
 "Cloud Resource Provider's Component Outline ID" => "Cloud Resource Provider's Image ID", # BZ 783128
 "Cloud Resource Zone Family" => "Cloud",
 "Cloud Resource Provider Cloud Resource Cluster" => "Provider Realm" # !!
}

contents = File.read(INPUT)

puts "Read #{contents.size} characters from #{INPUT}"

# Should we just pull the [!_\:] down here?
# Apply, in order, our exceptions, substitutions, the fix-up
# tweaks, and then undo the exception place-holders.
[EXCEPTIONS, SUBS, TWEAKS, EXCEPTIONS.invert].each do |hash|
  hash.each do |old,new|
    contents.gsub!(old, new)
  end
end

puts "Writing modified version to #{OUTPUT}"
puts " Try 'diff #{INPUT} #{OUTPUT}' to see what changed"

# Write output
outfile = File.open(OUTPUT, 'w')
outfile.write(contents)
