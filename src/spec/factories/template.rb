Factory.define :template do |i|
  i.sequence(:name) { |n| "template#{n}" }
  i.xml <<EOF
<image>
  <name>tpl</name>
  <repos>
    <repo>https://localhost/pulp/repos/jboss2</repo>
  </repos>
  <os name="Fedora" version="13" architecture="64-bit"/>
  <description/>
  <services/>
  <groups>
    <group>JBoss Core Packages</group>
  </groups>
  <packages>
    <package><name>jboss-as5</name><group>JBoss Core Packages</group></package>
    <package><name>jboss-jgroups</name><group>JBoss Core Packages</group></package>
  </packages>
</image>
EOF
end
