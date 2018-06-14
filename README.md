custom-nginx
============

This role is building and installing nginx directly out of the source code.

It's providing an easy way to patch the nginx sources according to your needs.

The role is not made for the configuration of the nginx service itself. There
are already powerful roles out there. If you're looking for one I'd highly
recommend [jdauphant.nginx](https://github.com/jdauphant/ansible-role-nginx).

Requirements
------------

This role requires Ansible 2.6.0 or higher in order to apply patches.

You can simply use pip to install the current release candidate:

```sh
pip install ansible==2.6.0rc2
```

All platform requirements are listed in the metadata file.

Install
-------

```sh
ansible-galaxy install timorunge.custom-nginx
```

Role Variables
--------------

The variables that can be passed to this role and a brief description about
them are as follows. (For all variables, take a look at [defaults/main.yml](defaults/main.yml))

```yaml
# Version definition:
custom_nginx_version: 1.14.0

# Basic settings for building nginx from sources.
# Align them with your build options.

# Paths:
custom_nginx_sbin_path: /usr/local/nginx/sbin/nginx
custom_nginx_conf_path: /usr/local/nginx/conf/nginx.conf
custom_nginx_pid_path: /var/run/nginx.pid
custom_nginx_lock_path: /var/lock/nginx.lock

# Directories:
custom_nginx_prefix_directory: /usr/local/nginx
custom_nginx_log_directory: /var/log/nginx
custom_nginx_cache_directory: /var/cache/nginx
custom_nginx_modules_directory: /usr/lib/nginx/modules

# In this section you can apply custom patches to nginx.
# You can find one example below in this document, see 2.1)
# Patches explained.
custom_nginx_patches:
  disable_h2c_table_update:
    dest_file: src/http/v2/ngx_http_v2.c
    patch_file: roles/loadbalancer/files/nginx-patches/disable_h2c_table_update.patch
    state: present

# Build options
custom_nginx_build_options:
  - "--prefix={{ custom_nginx_prefix_directory }}"
  - "--sbin-path={{ custom_nginx_sbin_path }}"
  - "--modules-path={{ custom_nginx_modules_directory }}"
  - "--conf-path={{ custom_nginx_conf_path }}"
  - "--pid-path={{ custom_nginx_pid_path }}"
  - "--lock-path={{ custom_nginx_lock_path }}"
  - "--error-log-path={{ custom_nginx_log_directory }}/error.log"
  - "--http-log-path={{ custom_nginx_log_directory }}/access.log"
  - "--http-client-body-temp-path={{ custom_nginx_cache_directory }}/client_temp"
  - "--http-proxy-temp-path={{ custom_nginx_cache_directory }}/proxy_temp"
  - "--http-fastcgi-temp-path={{ custom_nginx_cache_directory }}/fastcgi_temp"
  - "--http-uwsgi-temp-path={{ custom_nginx_cache_directory }}/uwsgi_temp"
  - "--http-scgi-temp-path={{ custom_nginx_cache_directory }}/scgi_temp"
  - "--user={{ custom_nginx_user }}"
  - "--group={{ custom_nginx_group }}"
  - '--with-compat'
  - '--with-file-aio'
  - '--with-threads'
  - '--with-http_addition_module'
  - '--with-http_auth_request_module'
  - '--with-http_dav_module'
  - '--with-http_flv_module'
  - '--with-http_gunzip_module'
  - '--with-http_gzip_static_module'
  - '--with-http_mp4_module'
  - '--with-http_random_index_module'
  - '--with-http_realip_module'
  - '--with-http_secure_link_module'
  - '--with-http_slice_module'
  - '--with-http_ssl_module'
  - '--with-http_stub_status_module'
  - '--with-http_sub_module'
  - '--with-http_v2_module'
  - '--with-mail'
  - '--with-mail_ssl_module'
  - '--with-stream'
  - '--with-stream_realip_module'
  - '--with-stream_ssl_module'
  - '--with-stream_ssl_preread_module'
```

Examples
--------

To keep the document lean the compile options are stripped.
You can find the nginx build options either in [this
document](#nginx-build-options) or online in the official [nginx
documentation](http://nginx.org/en/docs/configure.html).

## 1) Build nginx according to your needs

```yaml
- hosts: nginx
  vars:
    custom_nginx_version: 1.15.0
    custom_nginx_conf_path: /etc/nginx/nginx.conf
    custom_nginx_prefix_directory: /etc/nginx
    custom_nginx_sbin_path: /usr/sbin/nginx
    custom_nginx_build_options:
      - "--prefix={{ custom_nginx_prefix_directory }}"
      - "--sbin-path={{ custom_nginx_sbin_path }}"
      - "--modules-path={{ custom_nginx_modules_directory }}"
      - ...
  roles:
    - timorunge.custom-nginx
```

## 2) Apply patches to the source

```yaml
- hosts: nginx
  vars:
    custom_nginx_version: 1.15.0
    custom_nginx_patches:
      disable_h2c_table_update:
        dest_file: src/http/v2/ngx_http_v2.c
        patch_file: disable_h2c_table_update.patch
        state: present
    custom_nginx_build_options:
      - "--prefix={{ custom_nginx_prefix_directory }}"
      - "--sbin-path={{ custom_nginx_sbin_path }}"
      - "--modules-path={{ custom_nginx_modules_directory }}"
      - ...
  roles:
    - timorunge.custom-nginx
```

### 2.1) Patches (a little bit) explained

```yaml
custom_nginx_patches:
  disable_h2c_table_update:
    # The destination file which should get the patch:
    dest_file: src/http/v2/ngx_http_v2.c
    # The file, locally in your file system, which contains the patch.
    # If you're calling the custom_nginx_patches from another role which is
    # called e.g. loadbalancer and you've the file stored inside this role
    # it should look like this:
    patch_file: roles/loadbalancer/files/nginx-patches/disable_h2c_table_update.patch
    # State of the patch, can be "present" (default) or "absent":
    state: present
```

## 3) Override init.d and systemd templates

```yaml
- hosts: nginx
  vars:
    custom_nginx_version: 1.15.0
    custom_nginx_init_template: roles/loadbalancer/templates/nginx.service.j2
    custom_nginx_service_template: roles/loadbalancer/templates/nginx.init.j2
    custom_nginx_build_options:
      - "--prefix={{ custom_nginx_prefix_directory }}"
      - "--sbin-path={{ custom_nginx_sbin_path }}"
      - "--modules-path={{ custom_nginx_modules_directory }}"
      - ...
  roles:
    - timorunge.custom-nginx
```

nginx build options
-------------------

An overview of the build options for nginx (1.14.0).

```sh
--help                             print this message

--prefix=PATH                      set installation prefix
--sbin-path=PATH                   set nginx binary pathname
--modules-path=PATH                set modules path
--conf-path=PATH                   set nginx.conf pathname
--error-log-path=PATH              set error log pathname
--pid-path=PATH                    set nginx.pid pathname
--lock-path=PATH                   set nginx.lock pathname

--user=USER                        set non-privileged user for
                                   worker processes
--group=GROUP                      set non-privileged group for
                                   worker processes

--build=NAME                       set build name
--builddir=DIR                     set build directory

--with-select_module               enable select module
--without-select_module            disable select module
--with-poll_module                 enable poll module
--without-poll_module              disable poll module

--with-threads                     enable thread pool support

--with-file-aio                    enable file AIO support

--with-http_ssl_module             enable ngx_http_ssl_module
--with-http_v2_module              enable ngx_http_v2_module
--with-http_realip_module          enable ngx_http_realip_module
--with-http_addition_module        enable ngx_http_addition_module
--with-http_xslt_module            enable ngx_http_xslt_module
--with-http_xslt_module=dynamic    enable dynamic ngx_http_xslt_module
--with-http_image_filter_module    enable ngx_http_image_filter_module
--with-http_image_filter_module=dynamic
                                   enable dynamic ngx_http_image_filter_module
--with-http_geoip_module           enable ngx_http_geoip_module
--with-http_geoip_module=dynamic   enable dynamic ngx_http_geoip_module
--with-http_sub_module             enable ngx_http_sub_module
--with-http_dav_module             enable ngx_http_dav_module
--with-http_flv_module             enable ngx_http_flv_module
--with-http_mp4_module             enable ngx_http_mp4_module
--with-http_gunzip_module          enable ngx_http_gunzip_module
--with-http_gzip_static_module     enable ngx_http_gzip_static_module
--with-http_auth_request_module    enable ngx_http_auth_request_module
--with-http_random_index_module    enable ngx_http_random_index_module
--with-http_secure_link_module     enable ngx_http_secure_link_module
--with-http_degradation_module     enable ngx_http_degradation_module
--with-http_slice_module           enable ngx_http_slice_module
--with-http_stub_status_module     enable ngx_http_stub_status_module

--without-http_charset_module      disable ngx_http_charset_module
--without-http_gzip_module         disable ngx_http_gzip_module
--without-http_ssi_module          disable ngx_http_ssi_module
--without-http_userid_module       disable ngx_http_userid_module
--without-http_access_module       disable ngx_http_access_module
--without-http_auth_basic_module   disable ngx_http_auth_basic_module
--without-http_mirror_module       disable ngx_http_mirror_module
--without-http_autoindex_module    disable ngx_http_autoindex_module
--without-http_geo_module          disable ngx_http_geo_module
--without-http_map_module          disable ngx_http_map_module
--without-http_split_clients_module disable ngx_http_split_clients_module
--without-http_referer_module      disable ngx_http_referer_module
--without-http_rewrite_module      disable ngx_http_rewrite_module
--without-http_proxy_module        disable ngx_http_proxy_module
--without-http_fastcgi_module      disable ngx_http_fastcgi_module
--without-http_uwsgi_module        disable ngx_http_uwsgi_module
--without-http_scgi_module         disable ngx_http_scgi_module
--without-http_grpc_module         disable ngx_http_grpc_module
--without-http_memcached_module    disable ngx_http_memcached_module
--without-http_limit_conn_module   disable ngx_http_limit_conn_module
--without-http_limit_req_module    disable ngx_http_limit_req_module
--without-http_empty_gif_module    disable ngx_http_empty_gif_module
--without-http_browser_module      disable ngx_http_browser_module
--without-http_upstream_hash_module
                                   disable ngx_http_upstream_hash_module
--without-http_upstream_ip_hash_module
                                   disable ngx_http_upstream_ip_hash_module
--without-http_upstream_least_conn_module
                                   disable ngx_http_upstream_least_conn_module
--without-http_upstream_keepalive_module
                                   disable ngx_http_upstream_keepalive_module
--without-http_upstream_zone_module
                                   disable ngx_http_upstream_zone_module

--with-http_perl_module            enable ngx_http_perl_module
--with-http_perl_module=dynamic    enable dynamic ngx_http_perl_module
--with-perl_modules_path=PATH      set Perl modules path
--with-perl=PATH                   set perl binary pathname

--http-log-path=PATH               set http access log pathname
--http-client-body-temp-path=PATH  set path to store
                                   http client request body temporary files
--http-proxy-temp-path=PATH        set path to store
                                   http proxy temporary files
--http-fastcgi-temp-path=PATH      set path to store
                                   http fastcgi temporary files
--http-uwsgi-temp-path=PATH        set path to store
                                   http uwsgi temporary files
--http-scgi-temp-path=PATH         set path to store
                                   http scgi temporary files

--without-http                     disable HTTP server
--without-http-cache               disable HTTP cache

--with-mail                        enable POP3/IMAP4/SMTP proxy module
--with-mail=dynamic                enable dynamic POP3/IMAP4/SMTP proxy module
--with-mail_ssl_module             enable ngx_mail_ssl_module
--without-mail_pop3_module         disable ngx_mail_pop3_module
--without-mail_imap_module         disable ngx_mail_imap_module
--without-mail_smtp_module         disable ngx_mail_smtp_module

--with-stream                      enable TCP/UDP proxy module
--with-stream=dynamic              enable dynamic TCP/UDP proxy module
--with-stream_ssl_module           enable ngx_stream_ssl_module
--with-stream_realip_module        enable ngx_stream_realip_module
--with-stream_geoip_module         enable ngx_stream_geoip_module
--with-stream_geoip_module=dynamic enable dynamic ngx_stream_geoip_module
--with-stream_ssl_preread_module   enable ngx_stream_ssl_preread_module
--without-stream_limit_conn_module disable ngx_stream_limit_conn_module
--without-stream_access_module     disable ngx_stream_access_module
--without-stream_geo_module        disable ngx_stream_geo_module
--without-stream_map_module        disable ngx_stream_map_module
--without-stream_split_clients_module
                                   disable ngx_stream_split_clients_module
--without-stream_return_module     disable ngx_stream_return_module
--without-stream_upstream_hash_module
                                   disable ngx_stream_upstream_hash_module
--without-stream_upstream_least_conn_module
                                   disable ngx_stream_upstream_least_conn_module
--without-stream_upstream_zone_module
                                   disable ngx_stream_upstream_zone_module

--with-google_perftools_module     enable ngx_google_perftools_module
--with-cpp_test_module             enable ngx_cpp_test_module

--add-module=PATH                  enable external module
--add-dynamic-module=PATH          enable dynamic external module

--with-compat                      dynamic modules compatibility

--with-cc=PATH                     set C compiler pathname
--with-cpp=PATH                    set C preprocessor pathname
--with-cc-opt=OPTIONS              set additional C compiler options
--with-ld-opt=OPTIONS              set additional linker options
--with-cpu-opt=CPU                 build for the specified CPU, valid values:
                                   pentium, pentiumpro, pentium3, pentium4,
                                   athlon, opteron, sparc32, sparc64, ppc64

--without-pcre                     disable PCRE library usage
--with-pcre                        force PCRE library usage
--with-pcre=DIR                    set path to PCRE library sources
--with-pcre-opt=OPTIONS            set additional build options for PCRE
--with-pcre-jit                    build PCRE with JIT compilation support

--with-zlib=DIR                    set path to zlib library sources
--with-zlib-opt=OPTIONS            set additional build options for zlib
--with-zlib-asm=CPU                use zlib assembler sources optimized
                                   for the specified CPU, valid values:
                                   pentium, pentiumpro

--with-libatomic                   force libatomic_ops library usage
--with-libatomic=DIR               set path to libatomic_ops library sources

--with-openssl=DIR                 set path to OpenSSL library sources
--with-openssl-opt=OPTIONS         set additional build options for OpenSSL

--with-debug                       enable debug logging
```

Dependencies
------------

None

License
-------
BSD

Author Information
------------------

- Timo Runge
