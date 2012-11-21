FactoryGirl.define do
  factory :template, :class => Tim::Template do
    association :pool_family
    xml "<template>
           <name>Fedora 15</name>
             <description>desc</description>
             <os>
             <rootpw>password</rootpw>
              <name>Fedora</name>
              <arch>x86_64</arch>
              <version>15</version>
              <install type='url'>
                <url>http://download.fedoraproject.org/pub/fedora/linux/releases/15/Fedora/x86_64/os/</url>
              </install>
            </os>
            <repositories>
              <repository name='custom'>
                <url>http://repos.fedorapeople.org/repos/aeolus/demo/webapp/</url>
                <signed>false</signed>
              </repository>
            </repositories>
          </template>"
  end

  factory :template_i386, :parent => :template do
    xml "<template>
           <name>Fedora 15</name>
             <description>desc</description>
             <os>
             <rootpw>password</rootpw>
              <name>Fedora</name>
              <arch>i386</arch>
              <version>15</version>
              <install type='url'>
                <url>http://download.fedoraproject.org/pub/fedora/linux/releases/15/Fedora/x86_64/os/</url>
              </install>
            </os>
            <repositories>
              <repository name='custom'>
                <url>http://repos.fedorapeople.org/repos/aeolus/demo/webapp/</url>
                <signed>false</signed>
              </repository>
            </repositories>
          </template>"
  end
end
