#OVH-Server-Availability

##Review
This PERL script check Kimsufi/SYS servers availibility for purchase. 
You can chosse between sending an email or just showing in standard output as notification.

##Version
1.0

##Requirements
* LWP::UserAgent
* URI
* JSON
* Email::Send::SMTP::Gmail
* Config::General

##Installation

* Clone the repository (`git clone https://github.com/Shini31/OVH-Server-Availability.git`) or download and unpack the archives
* Install the PERL modules: `sudo cpan LWP::UserAgent URI JSON Email::Send::SMTP::Gmail Config::General`
* Take config.ini.example as a template, create a file config.ini and correct configuration according to your preferences
* Create a cron job to send you a mail periodically

##Configuration

Take config.ini.example as a template, create a file config.ini in same PERL script directory and correct configuration according to your preferences:
* `server`: Type of OVH/Kimsufi server (eg: `KS-1`, `SYS-IP-6`, `GAME-3`, `E3-SAT-1`, ...)
* `mail`: active or not sending an email (`0` or `1`)
  * `smtp-host`: SMTP host (eg: `smtp.example.org`)
  * `from`: sender email address (eg: `foo@example.com)
  * `to`: receiver email address (eg: `foobar@example.com`)
  * `timeout`: connection timeout (eg: `60`)
  * `auth`: activate or not SMTP authentication (`none` or `LOGIN`)
    * `smtp-user`: SMTP username (eg: `foo@example.com)
    * `smtp-password`: SMTP password (eg: `password)
  * `layer`: Security layer (`none`, `tls`, `ssl`)
  * `port`: SMTP port according to layer (`25`, `465`, `587`)
  * `debug`: active or not SMTP debug (`0` or `1`)



##Output example
    KS-2c
    =====
    Roubaix : Available


##Cron configuration
If you want receive email, you must a cron job.

    */10 * * * * ovh-server-availability.pl

