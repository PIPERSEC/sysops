# Few-Shot Example: Ansible Playbook

## Example: Web Server Configuration

### Input
"Create an Ansible playbook to configure an nginx web server with SSL"

### Output

**File: `playbooks/web-server.yml`**
```yaml
---
- name: Configure Nginx Web Server
  hosts: webservers
  become: yes
  vars:
    nginx_port: 80
    nginx_ssl_port: 443
    server_name: example.com
    document_root: /var/www/html
    ssl_cert_path: /etc/ssl/certs/server.crt
    ssl_key_path: /etc/ssl/private/server.key

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"

    - name: Install nginx
      package:
        name: nginx
        state: present

    - name: Install SSL packages
      package:
        name:
          - openssl
          - ssl-cert
        state: present

    - name: Create document root directory
      file:
        path: "{{ document_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'

    - name: Create SSL directory
      file:
        path: /etc/ssl/private
        state: directory
        owner: root
        group: root
        mode: '0700'

    - name: Copy SSL certificate
      copy:
        src: files/ssl/server.crt
        dest: "{{ ssl_cert_path }}"
        owner: root
        group: root
        mode: '0644'
      notify: reload nginx

    - name: Copy SSL private key
      copy:
        src: files/ssl/server.key
        dest: "{{ ssl_key_path }}"
        owner: root
        group: root
        mode: '0600'
      notify: reload nginx

    - name: Configure nginx from template
      template:
        src: templates/nginx-site.conf.j2
        dest: /etc/nginx/sites-available/{{ server_name }}
        owner: root
        group: root
        mode: '0644'
      notify: reload nginx

    - name: Enable nginx site
      file:
        src: /etc/nginx/sites-available/{{ server_name }}
        dest: /etc/nginx/sites-enabled/{{ server_name }}
        state: link
      notify: reload nginx

    - name: Disable default site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: reload nginx

    - name: Test nginx configuration
      command: nginx -t
      register: nginx_test
      changed_when: false

    - name: Ensure nginx is running and enabled
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Configure firewall for HTTP
      ufw:
        rule: allow
        port: '80'
        proto: tcp
      when: ansible_os_family == "Debian"

    - name: Configure firewall for HTTPS
      ufw:
        rule: allow
        port: '443'
        proto: tcp
      when: ansible_os_family == "Debian"

  handlers:
    - name: reload nginx
      service:
        name: nginx
        state: reloaded
```

**File: `templates/nginx-site.conf.j2`**
```nginx
# HTTP server - redirect to HTTPS
server {
    listen {{ nginx_port }};
    listen [::]:{{ nginx_port }};
    server_name {{ server_name }};

    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen {{ nginx_ssl_port }} ssl http2;
    listen [::]:{{ nginx_ssl_port }} ssl http2;
    server_name {{ server_name }};

    root {{ document_root }};
    index index.html index.htm;

    # SSL configuration
    ssl_certificate {{ ssl_cert_path }};
    ssl_certificate_key {{ ssl_key_path }};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/{{ server_name }}_access.log;
    error_log /var/log/nginx/{{ server_name }}_error.log;

    location / {
        try_files $uri $uri/ =404;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

**File: `inventory/hosts.ini`**
```ini
[webservers]
web01.example.com ansible_host=192.168.1.10
web02.example.com ansible_host=192.168.1.11

[webservers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
```

**Usage:**
```bash
# Run the playbook
ansible-playbook -i inventory/hosts.ini playbooks/web-server.yml

# Run with verbose output
ansible-playbook -i inventory/hosts.ini playbooks/web-server.yml -v

# Run with check mode (dry run)
ansible-playbook -i inventory/hosts.ini playbooks/web-server.yml --check

# Run with tags
ansible-playbook -i inventory/hosts.ini playbooks/web-server.yml --tags ssl
```
