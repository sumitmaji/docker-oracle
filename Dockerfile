FROM sumit/jdk1.7:latest
MAINTAINER Sumit Kumar Maji

#Java Environemtn Setup
ENV JAVA_HOME /usr/local/jdk1.7
ENV PATH $JAVA_HOME/bin:$PATH

# Install the packages libaio and bc
RUN apt-get update && apt-get install -yq libaio1
RUN apt-get install -yq original-awk
RUN apt-get install -yq bc
RUN apt-get install -yq openssh-client 
RUN apt-get install -yq openssh-server
RUN apt-get install -yq net-tools

# Copy the RPM file, modified init.ora, initXETemp.ora and the installation response file
# inside the image
ADD Disk1/oracle-xe_11.2.0-2_amd64.deb /tmp/oracle-xe_11.2.0-2_amd64.deb
ADD init.ora /tmp/init.ora
ADD initXETemp.ora /tmp/initXETemp.ora
ADD Disk1/response/xe.rsp /tmp/xe.rsp

RUN ln -s /usr/bin/awk /bin/awk
RUN mkdir /var/lock/subsys
RUN touch /var/lock/subsys/listener
ADD chkconfig /sbin/chkconfig
RUN chmod 755 /sbin/chkconfig

# Install the Oracle XE RPM
RUN dpkg --install /tmp/oracle-xe_11.2.0-2_amd64.deb

# Delete the Oracle XE RPM
RUN rm -f /tmp/oracle-xe_11.2.0-2_amd64.deb

# move the files init.ora and initXETemp.ora to the right directory
RUN mv /tmp/init.ora /u01/app/oracle/product/11.2.0/xe/config/scripts
RUN mv /tmp/initXETemp.ora /u01/app/oracle/product/11.2.0/xe/config/scripts

# Configure the database
RUN /etc/init.d/oracle-xe configure responseFile=/tmp/xe.rsp

# Create entries for the database in the profile
RUN echo 'export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe' >> /etc/profile.d/oracle_profile.sh
RUN echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> /etc/profile.d/oracle_profile.sh
RUN echo 'export ORACLE_SID=XE' >> /etc/profile.d/oracle_profile.sh

#RUN rm -rf /dev/shm
#RUN mkdir /dev/shm
#RUN mount -t tmpfs shmfs -o size=2048m /dev/shm
#ADD S01shm_load /etc/rc2.d/S01shm_load
#RUN chmod 755 /etc/rc2.d/S01shm_load
# Create ssh keys and change some ssh settings
RUN mkdir /var/run/sshd
RUN sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Change the root and oracle password to oracle
RUN echo root:oracle | chpasswd
RUN echo oracle:oracle | chpasswd

# Expose ports 22, 1521 and 8080
EXPOSE 22
EXPOSE 1521
EXPOSE 8080

# Change the hostname in the listener.ora file, start Oracle XE and the ssh daemon
CMD sed -i -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" /u01/app/oracle/product/11.2.0/xe/network/admin/listener.ora; \
service oracle-xe start; \
/usr/sbin/sshd -D
