  newpw=$(pwgen -1sB)
  cat /etc/hostapd/hostapd.conf | sed '/^wpa_passphrase=*/d'
  echo "wpa_passphrase=$newpw" >> /etc/hostapd/hostapd.conf
  restart hostap service
  mail the new password

