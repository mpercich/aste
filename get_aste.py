from bs4 import BeautifulSoup
from requests import Request, Session, utils
from requests.packages import urllib3
import csv
import json
import pyrebase
import googlemaps
import re
import sys
import locale
from pyfcm import FCMNotification
from subprocess import call
import os
import zipfile
import shutil
import datetime

start = datetime.datetime.now()

print('start:', start)

root = 'www.astegiudiziarie.it'
root_url = 'https://' + root

def send_request(body):
	global payload
	s = Session()
	proxies = {'https': 'https://us00749:Korcula1@proxymil.internal.unicredit.eu:80'}
	headers = {'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': str(len(body)), 'Accept-Encoding': 'utf-8'}
	req = Request('POST', root_url + '/default.aspx', headers=headers)
	prepped = req.prepare()
	prepped.body = body 
	#response = s.send(prepped, proxies=proxies, verify=False)
	response = s.send(prepped, verify=False)
	payload = get_response_fields(response)
	return response

def get_response_fields(response):
	fields = ''
	s = BeautifulSoup(response.text, 'html.parser')
	for tag in s.find('form', id='aspnetForm').find_all('input', type='hidden'):
		fields += tag['name'] + '=' + utils.quote(tag['value'], safe='') + '&'
	return fields
	
def grab(parameters, list):
	response = send_request(payload + parameters)
	soup = BeautifulSoup(response.text, 'html.parser')
	for record in soup.find_all('h4', class_='numerorecord'):
		immobile = {}
		key = {}
		temp = []
		for x, tag in enumerate(record.parent.find_all('td')):
			temp.append(tag.get_text(' ', strip=True))
		temp += [''] * (keys.index('Prezzo') - x)
		for y, tag in enumerate(record.parent.find_all('p', class_='psel')):
			temp.append(tag.get_text(' ', strip=True))
		temp += [''] * (keys.index('Note') - x - y - 1)
		conv = temp[keys.index('Prezzo')].strip('€ ').replace('.', '')
		try:
			temp[keys.index('Prezzo')] = locale.atof(conv)
		except:
			temp[keys.index('Prezzo')] = 0
		try:
			temp.append(record.parent.find('div', class_='schedadettagliata').find('a')['href'])	
		except:
			temp += ['']
		try:
			temp.append(record.parent.find('div', class_='elencoallegati').get_text('', strip=True))
		except:
			temp += ['']
		if temp[keys.index('Prezzo')] == 0:
			try:
				t = temp[keys.index('Descrizione')].split("Euro ")[1].rsplit(".", 1)[0].replace('.', '')
				temp[keys.index('Prezzo')] = locale.atof(t)
			except:
				pass
		found = re.search('Comune di (.+[0-9]{5})', temp[keys.index('Descrizione')])
		if found:
			geocode_result = gmaps.geocode(found.group(1))
			if geocode_result:
				temp.append(geocode_result[0]['formatted_address'])
				temp.append(str(geocode_result[0]['geometry']['location']['lat']) + ',' + str(geocode_result[0]['geometry']['location']['lng']))
		for x, tag in enumerate(temp):
			#print(keys[x], tag)
			if x == 0:
				chiave = tag
			else:
				immobile[keys[x]] = tag
		key[chiave] = immobile
		#print(immobile)
		list.append(key)
	return response

def send_notification(message_title, key, immobile):
	try:
		data_message = {
			'Codice' : k,
			'Prezzo' : immobile['Prezzo'],
			'Indirizzo' : immobile['Indirizzo']
		}
	except:
		return
	print(message_title, key, data_message)
	message_body = k + ' - ' + locale.currency(immobile['Prezzo'], grouping=True, international=True) + ' - ' + immobile['Indirizzo']
	result = push_service.notify_single_device(registration_id=registration_id, message_title=message_title, message_body=message_body, data_message=data_message)

def zipdir(path, ziph):
	abs_src = os.path.abspath(path)
	for root, dirs, files in os.walk(path):
		for file in files:
			absname = os.path.abspath(os.path.join(root, file))
			arcname = absname[len(abs_src) + 1:]
			ziph.write(absname, arcname)

config = {
  'apiKey': 'AIzaSyDdiBn8Y6ymkGwFbWvy-toDDZvGwfJT_-o',
  'authDomain': 'aste-404d3.firebaseapp.com',
  'databaseURL': 'https://aste-404d3.firebaseio.com/',
  'storageBucket': 'aste-404d3.appspot.com',
  'serviceAccount': 'serviceAccountKey.json'
}


locale.setlocale(locale.LC_ALL, 'it_IT')
urllib3.disable_warnings()
gmaps = googlemaps.Client(key='AIzaSyAW6WUTf8TVlGlpzbG0R_nYJxH79MXstxA') 
#gmaps = googlemaps.Client(key='AIzaSyAW6WUTf8TVlGlpzbG0R_nYJxH79MXstxA', requests_kwargs={'proxies': {'http': 'http://us00749:Korcula1@proxymil.internal.unicredit.eu:80', 'https': 'https://us00749:Korcula1@proxymil.internal.unicredit.eu:80'}, 'verify': False}) 
firebase = pyrebase.initialize_app(config)

db = firebase.database()
db_keys = db.shallow().get()


aste = []
keys = 'Codice', 'Tribunale', 'Tipologia', 'Ruolo', 'Data', 'Prezzo', 'Vendita', 'Lotto', 'Descrizione', 'Esito', 'Note', 'Link', 'Allegati', 'Indirizzo', 'Coordinate'
send_request('')
search = '__SCROLLPOSITIONX=0&__SCROLLPOSITIONY=0&__EVENTTARGET=&__EVENTARGUMENT=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24drpdTipologie=-99&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtFasciaPrezzoDa=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtFasciaPrezzoA=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24drpdProvincie=TS&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtComuneImmobile=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtCAP=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtIndirizzo=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24drpdTribunale=-99&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24drpdConcessionario=-99&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtNumeroProcedura=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtAnnoProcedura=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtCodiceA=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24txtDataVendita=&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24ChkAsteBandite=on&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24drdpVPregresse=-99&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24drpdNRecord=50&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24drpdOrdinamento=Prezzo_Base&ctl00%24ContentPlaceHolder1%24Mascherericerche1%24ImmobiliareGenerale1%24btnCerca=Cerca'

while True:
	response = grab(search, aste)
	search = '__SCROLLPOSITIONX=0&__SCROLLPOSITIONY=0&__EVENTTARGET=&__EVENTARGUMENT=&ctl00%24ContentPlaceHolder1%24Primasel2_1%24dlstPrimasel%24ctl50%24drpdPaginazione=1&ctl00%24ContentPlaceHolder1%24Primasel2_1%24dlstPrimasel%24ctl50%24btnSuccessiva=Pagina+successiva'
	if 'successiva' not in response.text:
		break

set_aste = set([k for immobile in aste for k in immobile.keys()]);
if db_keys.val() is None:
	set_db = set()
else:
	set_db = db_keys.val()

new_set = set_aste - set_db
removed_set = set_db - set_aste
common_set = set_aste - new_set

changed_set = set()
for k in common_set:
	for immobile in aste:
		if (list(immobile.keys())[0] == k):
			item = db.child(k).get().val()
			if (set(item.values()) - set(list(immobile.values())[0].values()) != set()):
				changed_set.add(k)
				#db.child(k).update(list(immobile.values())[0])
			break

storage = firebase.storage()
push_service = FCMNotification(api_key='AIzaSyDYSt7f8wPqlyMdvxf-hRBF-HJYUjqwUL8')
registration_id = 'Xsz-7-qxs0:APA91bGowRZ0369CGUCnLSEpE2Kmo8dfB3riIjUcwoEMCcnT1FDC6Jia-rR47UVEoVU4ZnO1G8D35VhLFuq_t_qEaSqa8Wsuz5n1Dq6nehmFlDiYICtNqOQhSRLc5vmoUqLTCqZ-EujZ'

for k in (removed_set | changed_set):
	storage.delete(k + '.zip')
	db.child(k).remove()

for k in (new_set | changed_set):
	for immobile in aste:
		if (list(immobile.keys())[0] == k):
			url = root_url + immobile[k]['Link']
			dest = os.path.dirname(os.getcwd())
			call(['wget', '-p', '-q', '-k', '-e robots=off', '-E', '-r', '-l1', '-P' + dest, '--restrict-file-names=windows', url])
			download_path = dest + '/' + root
			main = [filename for filename in os.listdir(download_path) if filename.startswith('seconda')]
			main_file = download_path + '/' + main[0]
			renamed_file = download_path + '/' + 'main.html'
			os.rename(main_file, renamed_file)
			with open(renamed_file, 'r+') as content_file:
				content = content_file.read()
				soup = BeautifulSoup(content, 'html.parser')
				try:
					soup.find('div', id='banner_cookie').decompose()
				except:
					pass
				[res.decompose() for res in soup.findAll('div', id='header')]
				[res.decompose() for res in soup.findAll('div', id='wrapper')]
				[res.decompose() for res in soup.findAll('div', id='footer')]
				[res.decompose() for res in soup.findAll('div', {'class': 'DivH1'})]
				[res.decompose() for res in soup.findAll('div', {'class': 'DivPreferito'})]
				[res.decompose() for res in soup.findAll('p', {'class': 'WarningDocNA'})]
				content_file.seek(0)
				content_file.write(str(soup))
				content_file.truncate()
				content_file.close()
			zip_name = k + '.zip'
			zip_path = dest + '/' + zip_name
			zipf = zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED)
			zipdir(download_path, zipf)
			zipf.close()
			shutil.rmtree(download_path)
			storage.child(zip_name).put(zip_path)
			db.child(k).set(list(immobile.values())[0])
			if k in new_set:
				title = 'Nuova asta'
			else:
				title = 'Asta modificata'
			send_notification(title, k, immobile[k])
			break

if (new_set != set()):
	print('Nuove', new_set)
if (removed_set != set()):
	print('Rimosse:', removed_set)
if (common_set != set()):	
	print('Comuni:', common_set)

#with open('aste.csv', 'w') as f:  # Just use 'w' mode in 3.x
#	w = csv.DictWriter(f, keys)
#	w.writeheader()
#	for immobile in aste:
#		#result = db.child(next(iter(immobile.keys()))).set(next(iter(immobile.values())))
#		k = dict(Codice=next(iter(immobile.keys())))
#		v = next(iter(immobile.values()))	
#		k.update(v)	
#		w.writerow(k)


print('Totali:', str(len(aste)), '\nNuove:', str(len(new_set)), '\nModificate:', str(len(changed_set)), '\nRimosse:', str(len(removed_set)))

end = datetime.datetime.now()
delta = end - start
print('end:', end)
print('delta:', delta)



