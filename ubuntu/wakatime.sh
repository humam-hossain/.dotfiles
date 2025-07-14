set -xe

echo "[CONFIG] wakatime api"
rm $HOME/.wakatime.cfg || true
echo "[settings]" >> $HOME/.wakatime.cfg
echo "api_url=https://wakapi.dev/api" >> $HOME/.wakatime.cfg
echo "api_key=810da25e-b74e-4f3b-88f5-77df36a7be96" >> $HOME/.wakatime.cfg

echo "[VERIFY] wakatime setup"
cat $HOME/.wakatime.cfg
