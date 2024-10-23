#!/bin/bash

# 問題 1：請求 Domain 名稱
read -p "請輸入您的域名 (例如 example.com): " domain

# 問題 2：請求 WordPress 資料夾路徑
read -p "請指定 WordPress 資料夾的完整路徑 (例如 /var/www/html/example): " wp_dir

# 如果資料夾不存在，則建立資料夾
if [ ! -d "$wp_dir" ]; then
  echo "$wp_dir 資料夾不存在，正在為您建立..."
  sudo mkdir -p "$wp_dir"
fi

# 更新並安裝必要套件
sudo apt update
sudo apt install -y apache2 mysql-server php libapache2-mod-php php-mysql curl unzip software-properties-common certbot python3-certbot-apache

# 下載並安裝 WordPress
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
sudo rsync -av wordpress/ "$wp_dir"

# 設定目錄權限
sudo chown -R www-data:www-data "$wp_dir"
sudo chmod -R 755 "$wp_dir"

# 啟用 Apache 模組
sudo a2enmod rewrite

# 設置 Apache 的 Virtual Host
vhost_config="<VirtualHost *:80>
    ServerAdmin webmaster@$domain
    ServerName $domain
    DocumentRoot $wp_dir
    <Directory $wp_dir>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>"

echo "正在為域名 $domain 配置 Apache Virtual Host..."
echo "$vhost_config" | sudo tee /etc/apache2/sites-available/$domain.conf

# 啟用新站點並重新加載 Apache
sudo a2ensite $domain.conf
sudo systemctl reload apache2

# 問題 3：請求電子郵件地址
read -p "請輸入您的電子郵件地址 (例如 user@example.com): " email

# 使用 Let's Encrypt 取得 SSL 憑證，只針對主域名
sudo certbot --apache -d $domain --non-interactive --agree-tos --email $email --deploy-hook "systemctl reload apache2" --deploy-hook "systemctl reload apache2"

# 檢查 Apache 服務狀態
sudo systemctl status apache2

# 通知用戶設置完成
echo "WordPress 安裝與 Apache 配置已完成，您的網站現在可以使用 https://$domain 來訪問。"
