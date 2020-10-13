Alô, mundo! no SCONE
===

Sobre este repositório
---

Este repositório é um material de apoio do minicurso _**"Processamento confidencial de dados de sensores na nuvem"**_ (Brito, Souza, Silva, Cavalcante e Silva), apresentado no XX Simpósio Brasileiro de Segurança da Informação e de Sistemas Computacionais (SBSEG 2020).

O objetivo desse repositório é agregar os recursos utilizados durante a Seção 1.4.6, entitulada **Desenvolvendo com SCONE**, que fornece uma introdução de conceitos básicos do SCONE (Secure CONtainer Environment), ambiente de execução blindada que permite que aplicações pré-existentes executem dentro de enclaves Intel SGX com pouca ou nenhuma necessidade de modificação de código.

Este repositório está organizado da seguinte forma:

```
.   
├── 0-alomundo           (ref. à Sec. 1.4.6.1 Alô, mundo!)
├── 1-atestacao          (ref. à Sec. 1.4.6.2 Atestação remota)
├── 2-segredos           (ref. à Sec. 1.4.6.3 Segredos)
├── 3-fspf               (ref. à Sec. 1.4.6.4 FSPF e volumes)
├── README.md            (instruções de uso do repositório)
└── clientcertreq.conf   (configuração para requisição de certificados de cliente)
```

Passo a passo
---

### Pré-requisitos

##### Pacotes 

Este tutorial requer as aplicações: curl, docker, envsubst e openssl. A maioria das distribuições já inclui boa parte dessas aplicações. Recomendamos que só se instale o que está em falta. Exemplos abaixo são para Ubuntu 18.04.

* curl: `sudo apt-get install curl`.
* docker: [documentação oficial](https://docs.docker.com/engine/install/ubuntu/), em inglês ou [documentação traduzida](https://www.digitalocean.com/community/tutorials/como-instalar-e-usar-o-docker-no-ubuntu-18-04-pt).
* envsubst: `sudo apt-get install gettext-base`.
* openssl: [documentação oficial](https://github.com/openssl/openssl/blob/master/INSTALL.md#installing-openssl), em inglês.

##### Intel SGX

É necessário instalar o _driver_ do Intel SGX ([documentação](https://sconedocs.github.io/sgxinstall/), em inglês). Sua interface é disponibilizada através de um dispositivo em `/dev/`. Aqui, assumimos `/dev/isgx`.

Para verificar se seu ambiente é capaz de executar esse tutorial, execute uma aplicação de teste.

```bash
$ docker run -dt --rm --name las --device /dev/isgx -p 18766:18766 sconecuratedimages/kubernetes:las >/dev/null
$ docker run -it --rm --device /dev/isgx -e SCONE_CAS_ADDR=scone-cas.cf -e SCONE_LAS_ADDR=172.17.0.1 -e SCONE_CONFIG_ID=test-environment/test clenimar/test-scone-environment:v0.1
Ambiente apto a rodar SCONE apps!
```

Limpe seu ambiente antes de prosseguir:

```bash
docker stop las >/dev/null
```

#### Preparação

1. Clone este repositório e defina o seu diretório de trabalho.

```bash
git clone https://git.lsd.ufcg.edu.br/lsd-sbseg-2020/alo-mundo-scone.git
cd alo-mundo-scone
export WORKDIR=$PWD
```

2. Defina o endereço do CAS e o seu identificador único para suas sessões.

```bash
export SCONE_CAS_ADDR=scone-cas.cf
export IDUNICO=$RANDOM-$RANDOM
```

3. Criação de certificados de cliente para contactar o CAS.

```bash
openssl req -newkey rsa:4096 -days 365 -nodes -x509 -out client.pem -keyout client-key.pem -config clientcertreq.conf
``` 

#### 1.4.6.1 Alô, mundo!

1. Mude o contexto para o diretório adequado.

```bash
cd $WORKDIR/0-alomundo
```

2. Construção da imagem de contêiner Alô, mundo! nativo (i.e., fora do SCONE).

```bash
docker build . -t sbseg-alo-mundo
```

3. Execução do contêiner Alô, mundo! nativo.

```bash
$ docker run -it --rm sbseg-alo-mundo
Alo, mundo!
```

4. Construção da imagem de contêiner Alô, mundo! SCONE.

```bash
docker build . -t sbseg-alo-mundo-scone -f scone.Dockerfile
```

5. Execução do contêiner Alô, mundo! SCONE e obtenção de identidade de enclave (MRENCLAVE).

```bash
$ docker run -it --rm --device /dev/isgx sbseg-alo-mundo-scone
Alo, mundo!
$ docker run -it --rm --device /dev/isgx -e SCONE_HASH=1 sbseg-alo-mundo-scone
41f0117a3c62966b48ef6e2388b5fe7ff719b1f48abbf417e855fff0546a8e0d
```

#### 1.4.6.2 Atestação remota

1. Mude o contexto para o diretório adequado.

```bash
cd $WORKDIR/1-atestacao
```

2. Iniciando o componente de atestação local do SCONE, LAS.

```bash
docker run -dt --rm --name las --device /dev/isgx -p 18766:18766 sconecuratedimages/kubernetes:las
```

3. Atualize o nome da sessão com seu ID único.

```bash
envsubst '$IDUNICO' < sessao.yml > sessao-atualizada.yml
```

4. Submissão de arquivo de sessão para o CAS utilizando a ferramenta cURL.

```bash
curl -v -k -s --cert $WORKDIR/client.pem  --key $WORKDIR/client-key.pem  --data-binary @sessao-atualizada.yml -X POST https://$SCONE_CAS_ADDR:8081/session
```

#### 1.4.6.3 Segredos

1. Mude o contexto para o diretório adequado.

```bash
cd $WORKDIR/2-segredos
```

2. Construção da imagem de contêiner da aplicação Alô, mundo! SCONE com segredos.

```bash
docker build . -t sbseg-alo-mundo-scone-segredos -f scone.Dockerfile
```

3. Atualize o nome da sessão com seu ID único.

```bash
envsubst '$IDUNICO' < sessao-segredos.yml > sessao-segredos-atualizada.yml
```

4. Submissão de arquivo de sessão para o CAS utilizando a ferramenta cURL.

```bash
curl -v -k -s --cert $WORKDIR/client.pem  --key $WORKDIR/client-key.pem  --data-binary @sessao-segredos-atualizada.yml -X POST https://$SCONE_CAS_ADDR:8081/session
```

5. Execução do contêiner Alô, mundo! SCONE com segredo sem atestação remota, o que causa erro.

```bash
$ docker run -it --rm --device /dev/isgx sbseg-alo-mundo-scone-segredos
Alo, mundo!
UM_SEGREDO: None
Traceback (most recent call last):
  File "programa.py", line 4, in <module>
    arquivo = open("/etc/segredo.txt", "r")
FileNotFoundError: [Errno 2] No such file or directory: '/etc/segredo.txt'
```

5. Execução do contêiner Alô, mundo! SCONE com segredo com atestação remota.

```bash
$ export SCONE_LAS_ADDR=172.17.0.1
$ export SCONE_CONFIG_ID=sessao-exemplo-segredos-$IDUNICO/alo-mundo
$ docker run -it --rm --device /dev/isgx \
                -e SCONE_CAS_ADDR=$SCONE_CAS_ADDR \
                -e SCONE_LAS_ADDR=$SCONE_LAS_ADDR \
                -e SCONE_CONFIG_ID=$SCONE_CONFIG_ID \
                sbseg-alo-mundo-scone-segredos
Alo, mundo!
UM_SEGREDO: ^/Z/!Cm1D&Q84BP'
isto eh um segredo!!!
```

#### 1.4.6.4 FSPF e volumes

1. Mude o contexto para o diretório adequado.

```bash
cd $WORKDIR/3-fspf
```

2. Criação de regiões FSPF criptografadas através da SCONE CLI.

```bash
mkdir fspf native-files encrypted-files
cp programa.py native-files/
chmod +x fspf.sh
cp fspf.sh fspf/
docker run -it --rm --device /dev/isgx \
        -v $PWD/fspf:/fspf \
        -v $PWD/native-files:/native-files \
        -v $PWD/encrypted-files:/app \
        sconecuratedimages/kubernetes:python-3.7.3-alpine3.10-scone4.2 \
        bash -c /fspf/fspf.sh
```

3. O arquivos em `encrypted-files` estão agora criptografados.

```bash
$ cat encrypted-files/programa.py
��ڻ�zoA!�^�
```

4. Construção da imagem de contêiner da aplicação Alô, mundo! SCONE com FSPF e código criptografado.

```bash
docker build . -t sbseg-alo-mundo-scone-fspf -f scone.Dockerfile
```

5. Recuperação da chave de criptografia e da _tag_ das regiões criptografadas criadas.

```bash
export SCONE_FSPF_KEY=$(cat native-files/keytag | awk '{print $11}')
export SCONE_FSPF_TAG=$(cat native-files/keytag | awk '{print $9}')
```

6. Substituição de `$SCONE_FSPF_KEY` e `$SCONE_FSPF_TAG` no arquivo de sessão. Esse processo pode ser automatizado através da ferramenta `envsubst`, que escreve o arquivo de sessão atualizado em disco.

```bash
envsubst '$IDUNICO $SCONE_FSPF_KEY $SCONE_FSPF_TAG' < sessao-fspf.yml > sessao-fspf-atualizada.yml
```

7. Submissão de arquivo de sessão para o CAS utilizando a ferramenta cURL. Perceba que estamos enviando o arquivo atualizado com a chave de criptografia e a _tag_ das regiões FSPF.

```bash
curl -v -k -s --cert $WORKDIR/client.pem  --key $WORKDIR/client-key.pem  --data-binary @sessao-fspf-atualizada.yml -X POST https://$SCONE_CAS_ADDR:8081/session
```

8. Execução do contêiner Alô, mundo! SCONE com FSPF e código criptografado sem atestação remota, o que causa erro.

```bash
$ docker run -it --rm --device /dev/isgx sbseg-alo-mundo-scone-fspf
File "/app/programa.py", line 1
SyntaxError: Non-UTF-8 code starting with '\xc1' in file /app/programa.py on line 
1, but no encoding declared; see http://python.org/dev/peps/pep-0263/ for details
```

9. Execução do contêiner Alô, mundo! SCONE com FSPF e código criptografado com atestação remota.

```bash
$ export SCONE_LAS_ADDR=172.17.0.1
$ export SCONE_CONFIG_ID=sessao-exemplo-fspf-$IDUNICO/alo-mundo
$ docker run -it --rm --device /dev/isgx \
        -e SCONE_CAS_ADDR=$SCONE_CAS_ADDR \
        -e SCONE_LAS_ADDR=$SCONE_LAS_ADDR \
        -e SCONE_CONFIG_ID=$SCONE_CONFIG_ID \
        sbseg-alo-mundo-scone-fspf
Alo, mundo!
UM_SEGREDO: Nrj05qjgqHjDlYJd
isto é um segredo!!!
```

