#
class jenkins {

    # get key
    exec { 'install_jenkins_key':
        command => "curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
        path => "/usr/bin:/usr/sbin:/bin"
    }

        # source file
    file { '/etc/apt/sources.list.d/jenkins.list':
        content => "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/\n",
        mode    => '0644',
        owner   => root,
        group   => root,
        require => Exec['install_jenkins_key'],
    } 

    # update
    exec { 'apt-get update':
        command => '/usr/bin/apt-get update',
    }

    #install jenkins
    $enhancers = [ 'openjdk-11-jre', 'jenkins' ]

    # jenkins package
    package { $enhancers:
        ensure  => installed,
        require => [
            File['/etc/apt/sources.list.d/jenkins.list'],
            Exec['apt-get update']
        ]
    } -> exec { 'replace_jenkins_port': #Reemplazo el puerto de jenkins para que este escuchando en el 8082
        command => "/bin/sed -i -- 's/JENKINS_PORT=8080/JENKINS_PORT=8082/g' /lib/systemd/system/jenkins.service",

    } -> exec { 'reload': # Notifico al gestor de servicios que un archivo cambio
        command => '/bin/systemctl restart jenkins',
        path    => '/usr/bin:/usr/sbin:/bin',
        unless  => 'netstat -pant |grep LISTEN |grep 8082 | awk  \'{print $7}\'',
    }

    service { 'jenkins':
        ensure => running,
        enable => true,
    }

    user { 'jenkins':
        ensure   => present,
        password => '$1$hrl1RNSP$DoKnhDdeCLlW.QJGLY8dj1',
        home     => '/var/lib/jenkins',
        shell    => '/bin/bash',
    }

}
