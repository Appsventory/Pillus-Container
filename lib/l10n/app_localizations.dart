import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Global localizations for the whole app (id / en / zh / ja).
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('id'),
    Locale('zh'),
    Locale('ja'),
  ];

  String get _code {
    final c = locale.languageCode;
    if (c == 'id' || c == 'zh' || c == 'ja' || c == 'en') return c;
    return 'en';
  }

  String _t(String key) {
    final table = _strings[_code] ?? _strings['en']!;
    return table[key] ?? _strings['en']![key] ?? key;
  }

  String get appTitle => _t('appTitle');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get save => _t('save');
  String get create => _t('create');
  String get update => _t('update');
  String get retry => _t('retry');
  String get tryAgain => _t('tryAgain');
  String get refresh => _t('refresh');
  String get loading => _t('loading');
  String get errorGeneric => _t('errorGeneric');
  String get back => _t('back');
  String get more => _t('more');
  String get moreActions => _t('moreActions');
  String get name => _t('name');
  String get status => _t('status');
  String get size => _t('size');
  String get unknown => _t('unknown');
  String get confirm => _t('confirm');
  String get close => _t('close');
  String get search => _t('search');
  String get optional => _t('optional');
  String get requiredField => _t('requiredField');
  String get saved => _t('saved');
  String get resetDefault => _t('resetDefault');
  String get connect => _t('connect');
  String get disconnect => _t('disconnect');
  String get start => _t('start');
  String get stop => _t('stop');
  String get restart => _t('restart');
  String get pause => _t('pause');
  String get unpause => _t('unpause');
  String get rename => _t('rename');
  String get inspect => _t('inspect');
  String get logs => _t('logs');
  String get exec => _t('exec');
  String get stats => _t('stats');
  String get pull => _t('pull');
  String get remove => _t('remove');
  String get edit => _t('edit');
  String get online => _t('online');
  String get offline => _t('offline');
  String get running => _t('running');
  String get paused => _t('paused');
  String get restarting => _t('restarting');
  String get checking => _t('checking');
  String get reachable => _t('reachable');
  String get unreachable => _t('unreachable');
  String get settings => _t('settings');
  String get settingsSubtitle => _t('settingsSubtitle');
  String get appearance => _t('appearance');
  String get theme => _t('theme');
  String get themeSystem => _t('themeSystem');
  String get themeLight => _t('themeLight');
  String get themeDark => _t('themeDark');
  String get language => _t('language');
  String get langAuto => _t('langAuto');
  String get langId => _t('langId');
  String get langEn => _t('langEn');
  String get langZh => _t('langZh');
  String get langJa => _t('langJa');
  String get dockerConfig => _t('dockerConfig');
  String get dockerCliPath => _t('dockerCliPath');
  String get dockerCliPathHint => _t('dockerCliPathHint');
  String get logLines => _t('logLines');
  String get logLinesDesc => _t('logLinesDesc');
  String get lines100 => _t('lines100');
  String get lines500 => _t('lines500');
  String get lines1000 => _t('lines1000');
  String get dashboard => _t('dashboard');
  String get addServer => _t('addServer');
  String get addServerTitle => _t('addServerTitle');
  String get editServerTitle => _t('editServerTitle');
  String get editServer => _t('editServer');
  String get reconnect => _t('reconnect');
  String get saveChanges => _t('saveChanges');
  String get noServersTitle => _t('noServersTitle');
  String get noServersBody => _t('noServersBody');
  String get servers => _t('servers');
  String get deleteServerTitle => _t('deleteServerTitle');
  String get justNow => _t('justNow');
  String get neverConnected => _t('neverConnected');
  String get cpu => _t('cpu');
  String get ram => _t('ram');
  String get disk => _t('disk');
  String get live => _t('live');
  String get tabContainers => _t('tabContainers');
  String get tabImages => _t('tabImages');
  String get tabVolumes => _t('tabVolumes');
  String get tabNetwork => _t('tabNetwork');
  String get tabFiles => _t('tabFiles');
  String get serverLabel => _t('serverLabel');
  String get resources => _t('resources');
  String get terminalHost => _t('terminalHost');
  String get compose => _t('compose');
  String get composeStacks => _t('composeStacks');
  String get dockerCompose => _t('dockerCompose');
  String get dockerManager => _t('dockerManager');
  String get containersTitle => _t('containersTitle');
  String get containersSubtitle => _t('containersSubtitle');
  String get loadingContainers => _t('loadingContainers');
  String get noContainersFound => _t('noContainersFound');
  String get createContainerHint => _t('createContainerHint');
  String get deleteContainerTitle => _t('deleteContainerTitle');
  String get renameContainer => _t('renameContainer');
  String get containerName => _t('containerName');
  String get newName => _t('newName');
  String get imagesTitle => _t('imagesTitle');
  String get imagesSubtitle => _t('imagesSubtitle');
  String get loadingImages => _t('loadingImages');
  String get noImagesFound => _t('noImagesFound');
  String get pullImageHint => _t('pullImageHint');
  String get pullImage => _t('pullImage');
  String get imageName => _t('imageName');
  String get imageDetails => _t('imageDetails');
  String get volumesTitle => _t('volumesTitle');
  String get volumesSubtitle => _t('volumesSubtitle');
  String get loadingVolumes => _t('loadingVolumes');
  String get noVolumesFound => _t('noVolumesFound');
  String get createVolumeHint => _t('createVolumeHint');
  String get createVolume => _t('createVolume');
  String get volumeName => _t('volumeName');
  String get deleteVolumeTitle => _t('deleteVolumeTitle');
  String get networkTitle => _t('networkTitle');
  String get networkSubtitle => _t('networkSubtitle');
  String get loadingNetworks => _t('loadingNetworks');
  String get noNetworksFound => _t('noNetworksFound');
  String get createNetworkHint => _t('createNetworkHint');
  String get createNetwork => _t('createNetwork');
  String get networkName => _t('networkName');
  String get driver => _t('driver');
  String get scope => _t('scope');
  String get builtInNetwork => _t('builtInNetwork');
  String get deleteNetworkTitle => _t('deleteNetworkTitle');
  String get connectContainer => _t('connectContainer');
  String get connectContainerHint => _t('connectContainerHint');
  String get connectedContainers => _t('connectedContainers');
  String get containersOnNetwork => _t('containersOnNetwork');
  String get noConnectedContainers => _t('noConnectedContainers');
  String get allContainersConnected => _t('allContainersConnected');
  String get filesTitle => _t('filesTitle');
  String get filesSubtitle => _t('filesSubtitle');
  String get loadingFiles => _t('loadingFiles');
  String get folderEmpty => _t('folderEmpty');
  String get uploadOrCreateHint => _t('uploadOrCreateHint');
  String get newFolder => _t('newFolder');
  String get newFile => _t('newFile');
  String get startTyping => _t('startTyping');
  String get uploadFile => _t('uploadFile');
  String get folder => _t('folder');
  String get parentDirectory => _t('parentDirectory');
  String get rootDirectory => _t('rootDirectory');
  String get gridView => _t('gridView');
  String get listView => _t('listView');
  String get deleteFileTitle => _t('deleteFileTitle');
  String get noComposeStacks => _t('noComposeStacks');
  String get stopStackTitle => _t('stopStackTitle');
  String get down => _t('down');
  String get editContents => _t('editContents');
  String get openFileLocation => _t('openFileLocation');
  String get logsEmpty => _t('logsEmpty');
  String get logsEmptyShort => _t('logsEmptyShort');
  String get loadMore => _t('loadMore');
  String get ipAlreadyRegistered => _t('ipAlreadyRegistered');
  String get continueAnyway => _t('continueAnyway');
  String get connectAndSave => _t('connectAndSave');
  String get password => _t('password');
  String get privateKey => _t('privateKey');
  String get privateKeyPem => _t('privateKeyPem');
  String get passphraseOptional => _t('passphraseOptional');
  String get hostIp => _t('hostIp');
  String get port => _t('port');
  String get username => _t('username');
  String get serverName => _t('serverName');
  String get connecting => _t('connecting');
  String get failedConnectCreds => _t('failedConnectCreds');
  String get general => _t('general');
  String get configuration => _t('configuration');
  String get host => _t('host');
  String get verifyHost => _t('verifyHost');
  String get fingerprintChanged => _t('fingerprintChanged');
  String get fingerprintChangedBody => _t('fingerprintChangedBody');
  String get fingerprintNewBody => _t('fingerprintNewBody');
  String get trustAndContinue => _t('trustAndContinue');
  String get keyType => _t('keyType');
  String get liveStats => _t('liveStats');
  String get waitingStats => _t('waitingStats');
  String get statsLiveHint => _t('statsLiveHint');
  String get memory => _t('memory');
  String get networkIo => _t('networkIo');
  String get blockIo => _t('blockIo');
  String get pids => _t('pids');
  String get ports => _t('ports');
  String get notPublished => _t('notPublished');
  String get state => _t('state');
  String get image => _t('image');
  String get command => _t('command');
  String get created => _t('created');
  String get startedAt => _t('startedAt');
  String get restartCount => _t('restartCount');
  String get restartPolicy => _t('restartPolicy');
  String get networkMode => _t('networkMode');
  String get workingDir => _t('workingDir');
  String get mounts => _t('mounts');
  String get networks => _t('networks');
  String get source => _t('source');
  String get architecture => _t('architecture');
  String get config => _t('config');
  String get container => _t('container');
  String get sessionEnded => _t('sessionEnded');
  String get featureComingSoon => _t('featureComingSoon');
  String get networkFeatureDesc => _t('networkFeatureDesc');
  String get filesFeatureDesc => _t('filesFeatureDesc');

  String get searchPullImage => _t('searchPullImage');
  String get buildImage => _t('buildImage');
  String get searchImageHint => _t('searchImageHint');
  String get imageTag => _t('imageTag');
  String get useDockerfile => _t('useDockerfile');
  String get dockerfileContent => _t('dockerfileContent');
  String get buildContextPath => _t('buildContextPath');
  String get searchingImages => _t('searchingImages');
  String get noSearchResults => _t('noSearchResults');
  String get buildingImage => _t('buildingImage');
  String get pullingImage => _t('pullingImage');
  String get stars => _t('stars');
  String get official => _t('official');

  String get pullExact => _t('pullExact');
  String get pullExactHint => _t('pullExactHint');
  String get entrypoint => _t('entrypoint');
  String get envVars => _t('envVars');
  String get osLabel => _t('osLabel');
  String get execTerminal => _t('execTerminal');
  String get download => _t('download');
  String get dockerLabel => _t('dockerLabel');
  String get fileLabel => _t('fileLabel');

  String get createContainer => _t('createContainer');
  String get optionalAuto => _t('optionalAuto');
  String get network => _t('network');
  String get portMapping => _t('portMapping');
  String get hostPort => _t('hostPort');
  String get containerPort => _t('containerPort');
  String get protocol => _t('protocol');
  String get volumeMounts => _t('volumeMounts');
  String get hostPath => _t('hostPath');
  String get containerPath => _t('containerPath');
  String get readOnly => _t('readOnly');
  String get autoRemove => _t('autoRemove');
  String get autoRemoveHint => _t('autoRemoveHint');
  String get privileged => _t('privileged');
  String failedSearch(String e) => _t('failedSearch').replaceAll('{e}', e);
  String failedBuild(String e) => _t('failedBuild').replaceAll('{e}', e);

  String failedCreateContainer(String e) =>
      _t('failedCreateContainer').replaceAll('{e}', e);
  String failed(String e) => _t('failed').replaceAll('{e}', e);
  String serversOnline(int n, int total) => _t(
    'serversOnline',
  ).replaceAll('{n}', '$n').replaceAll('{total}', '$total');
  String deleteServerBody(String name) =>
      _t('deleteServerBody').replaceAll('{name}', name);
  String minutesAgo(int n) => _t('minutesAgo').replaceAll('{n}', '$n');
  String hoursAgo(int n) => _t('hoursAgo').replaceAll('{n}', '$n');
  String daysAgo(int n) => _t('daysAgo').replaceAll('{n}', '$n');
  String lastData(String time) => _t('lastData').replaceAll('{time}', time);
  String containersRunning(int running, int total) => _t(
    'containersRunning',
  ).replaceAll('{running}', '$running').replaceAll('{total}', '$total');
  String msLatency(int n) => _t('msLatency').replaceAll('{n}', '$n');
  String deleteContainerBody(String name) =>
      _t('deleteContainerBody').replaceAll('{name}', name);
  String failedLoadContainers(String e) =>
      _t('failedLoadContainers').replaceAll('{e}', e);
  String failedLoadImages(String e) =>
      _t('failedLoadImages').replaceAll('{e}', e);
  String failedPull(String e) => _t('failedPull').replaceAll('{e}', e);
  String failedInspect(String e) => _t('failedInspect').replaceAll('{e}', e);
  String deleteVolumeBody(String name) =>
      _t('deleteVolumeBody').replaceAll('{name}', name);
  String failedLoadVolumes(String e) =>
      _t('failedLoadVolumes').replaceAll('{e}', e);
  String failedCreateVolume(String e) =>
      _t('failedCreateVolume').replaceAll('{e}', e);
  String failedDelete(String e) => _t('failedDelete').replaceAll('{e}', e);
  String failedLoadNetworks(String e) =>
      _t('failedLoadNetworks').replaceAll('{e}', e);
  String failedCreateNetwork(String e) =>
      _t('failedCreateNetwork').replaceAll('{e}', e);
  String failedConnect(String e) => _t('failedConnect').replaceAll('{e}', e);
  String failedDisconnect(String e) =>
      _t('failedDisconnect').replaceAll('{e}', e);
  String deleteFileBody(String name) =>
      _t('deleteFileBody').replaceAll('{name}', name);
  String deleteImageBody(String name) =>
      _t('deleteImageBody').replaceAll('{name}', name);
  String deleteNetworkBody(String name) =>
      _t('deleteNetworkBody').replaceAll('{name}', name);
  String deleteFolderBody(String name) =>
      _t('deleteFolderBody').replaceAll('{name}', name);
  String savedTo(String path) => _t('savedTo').replaceAll('{path}', path);
  String failedReadFile(String e) => _t('failedReadFile').replaceAll('{e}', e);
  String failedCreateFolder(String e) =>
      _t('failedCreateFolder').replaceAll('{e}', e);
  String failedOpenFolder(String e) =>
      _t('failedOpenFolder').replaceAll('{e}', e);
  String failedDownload(String e) => _t('failedDownload').replaceAll('{e}', e);
  String failedUpload(String e) => _t('failedUpload').replaceAll('{e}', e);
  String failedRename(String e) => _t('failedRename').replaceAll('{e}', e);
  String uploadSuccess(String name) =>
      _t('uploadSuccess').replaceAll('{name}', name);
  String stopStackBody(String name) =>
      _t('stopStackBody').replaceAll('{name}', name);
  String failedLoadStacks(String e) =>
      _t('failedLoadStacks').replaceAll('{e}', e);
  String logsFor(String name) => _t('logsFor').replaceAll('{name}', name);
  String showingLastLines(int n) =>
      _t('showingLastLines').replaceAll('{n}', '$n');
  String failedLoadLogs(String e) => _t('failedLoadLogs').replaceAll('{e}', e);
  String failedSave(String e) => _t('failedSave').replaceAll('{e}', e);
  String hostAlreadyUsed(String host, String name) => _t(
    'hostAlreadyUsed',
  ).replaceAll('{host}', host).replaceAll('{name}', name);
  String statsTitle(String name) => _t('statsTitle').replaceAll('{name}', name);
  String failedLoadStats(String e) =>
      _t('failedLoadStats').replaceAll('{e}', e);
  String failedLoadDetails(String e) =>
      _t('failedLoadDetails').replaceAll('{e}', e);
  String terminalHostTitle(String name) =>
      _t('terminalHostTitle').replaceAll('{name}', name);
  String failedOpenTerminal(String e) =>
      _t('failedOpenTerminal').replaceAll('{e}', e);
  String failedOpenHostTerminal(String e) =>
      _t('failedOpenHostTerminal').replaceAll('{e}', e);

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'Docker Manager',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'save': 'Save',
      'create': 'Create',
      'update': 'Update',
      'retry': 'Retry',
      'tryAgain': 'Try Again',
      'refresh': 'Refresh',
      'loading': 'Loading...',
      'errorGeneric': 'Something went wrong',
      'back': 'Back',
      'more': 'More',
      'moreActions': 'More actions',
      'name': 'Name',
      'status': 'Status',
      'size': 'Size',
      'unknown': 'Unknown',
      'confirm': 'Confirm',
      'close': 'Close',
      'search': 'Search',
      'optional': 'Optional',
      'requiredField': 'Required',
      'failed': 'Failed: {e}',
      'saved': 'Saved',
      'resetDefault': 'Reset default',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'start': 'Start',
      'stop': 'Stop',
      'restart': 'Restart',
      'pause': 'Pause',
      'unpause': 'Unpause',
      'rename': 'Rename',
      'inspect': 'Inspect',
      'logs': 'Logs',
      'exec': 'Exec',
      'stats': 'Stats',
      'pull': 'Pull',
      'remove': 'Remove',
      'edit': 'Edit',
      'online': 'Online',
      'offline': 'Offline',
      'running': 'Running',
      'paused': 'Paused',
      'restarting': 'Restarting',
      'checking': 'Checking...',
      'reachable': 'Reachable',
      'unreachable': 'Unreachable',
      'settings': 'Settings',
      'settingsSubtitle': 'Application preferences',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'language': 'Language',
      'langAuto': 'Auto',
      'langId': 'Indonesia',
      'langEn': 'English',
      'langZh': '中文',
      'langJa': '日本語',
      'dockerConfig': 'Docker configuration',
      'dockerCliPath': 'Docker CLI path',
      'dockerCliPathHint':
          'Docker binary on the remote server (e.g. docker or /usr/bin/docker)',
      'logLines': 'Default log lines',
      'logLinesDesc':
          'Trailing lines fetched when opening container/compose logs',
      'lines100': '100 lines',
      'lines500': '500 lines',
      'lines1000': '1000 lines',
      'dashboard': 'Dashboard',
      'addServer': 'Add server',
      'addServerTitle': 'Add Server',
      'editServerTitle': 'Edit Server',
      'editServer': 'Edit Server',
      'reconnect': 'Reconnect',
      'saveChanges': 'Save Changes',
      'noServersTitle': 'No servers saved yet',
      'noServersBody': 'Add your first server to start monitoring Docker.',
      'servers': 'Servers',
      'serversOnline': '{n} of {total} servers online',
      'deleteServerTitle': 'Delete Server?',
      'deleteServerBody':
          'Server "{name}" and its credentials will be removed. This cannot be undone.',
      'justNow': 'just now',
      'minutesAgo': '{n} min ago',
      'hoursAgo': '{n} hours ago',
      'daysAgo': '{n} days ago',
      'neverConnected': 'Never connected — tap to connect',
      'lastData': 'Last data: {time}',
      'containersRunning': '{running} / {total} running',
      'cpu': 'CPU',
      'ram': 'RAM',
      'disk': 'Disk',
      'live': 'Live',
      'msLatency': '{n} ms',
      'tabContainers': 'Containers',
      'tabImages': 'Images',
      'tabVolumes': 'Volumes',
      'tabNetwork': 'Network',
      'tabFiles': 'Files',
      'serverLabel': 'Server',
      'resources': 'RESOURCES',
      'terminalHost': 'Host Terminal',
      'compose': 'Compose',
      'composeStacks': 'Compose Stacks',
      'dockerCompose': 'Docker Compose',
      'dockerManager': 'Docker Manager',
      'containersTitle': 'Containers',
      'containersSubtitle': 'Manage Docker containers',
      'loadingContainers': 'Loading containers...',
      'noContainersFound': 'No containers found',
      'createContainerHint': 'Create a container or deploy a Compose stack.',
      'deleteContainerTitle': 'Delete Container?',
      'deleteContainerBody':
          '"{name}" will be permanently removed from the server.',
      'renameContainer': 'Rename Container',
      'containerName': 'Container name',
      'newName': 'New name',
      'failedLoadContainers': 'Failed to load containers: {e}',
      'imagesTitle': 'Images',
      'imagesSubtitle': 'Manage Docker images',
      'loadingImages': 'Loading images...',
      'noImagesFound': 'No images found',
      'pullImageHint': 'Pull an image from a registry to get started.',
      'pullImage': 'Pull Image',
      'searchPullImage': 'Cari & Pull',
      'buildImage': 'Build Image',
      'searchImageHint': 'Cari di Docker Hub…',
      'imageTag': 'Tag',
      'useDockerfile': 'Pakai Dockerfile',
      'dockerfileContent': 'Isi Dockerfile',
      'buildContextPath': 'Path context build',
      'searchingImages': 'Mencari…',
      'noSearchResults': 'Tidak ada hasil',
      'buildingImage': 'Sedang build image…',
      'pullingImage': 'Sedang pull image…',
      'failedSearch': 'Gagal cari: {e}',
      'failedBuild': 'Gagal build: {e}',
      'stars': 'bintang',
      'official': 'Official',
      'imageName': 'Image name',
      'imageDetails': 'Image Details',
      'failedLoadImages': 'Failed to load images: {e}',
      'failedPull': 'Failed to pull: {e}',
      'failedInspect': 'Failed to inspect: {e}',
      'volumesTitle': 'Volumes',
      'volumesSubtitle': 'Manage Docker persistent storage',
      'loadingVolumes': 'Loading volumes...',
      'noVolumesFound': 'No volumes found',
      'createVolumeHint': 'Create a volume to persist container data.',
      'createVolume': 'Create Volume',
      'volumeName': 'Volume name',
      'deleteVolumeTitle': 'Delete Volume?',
      'deleteVolumeBody':
          '"{name}" will be deleted. If still used by a container, deletion may fail.',
      'failedLoadVolumes': 'Failed to load volumes: {e}',
      'failedCreateVolume': 'Failed to create volume: {e}',
      'failedDelete': 'Failed to delete: {e}',
      'networkTitle': 'Network',
      'networkSubtitle': 'Manage Docker networks',
      'loadingNetworks': 'Loading networks...',
      'noNetworksFound': 'No networks found',
      'createNetworkHint': 'Create a network to get started.',
      'createNetwork': 'Create Network',
      'networkName': 'Network name',
      'driver': 'Driver',
      'scope': 'Scope',
      'builtInNetwork': 'Built-in Docker network',
      'deleteNetworkTitle': 'Delete Network?',
      'connectContainer': 'Connect Container',
      'connectContainerHint': 'Connect a running container to this network.',
      'connectedContainers': 'Connected Containers',
      'containersOnNetwork': 'Containers attached to this network',
      'noConnectedContainers': 'No connected containers',
      'allContainersConnected':
          'All running containers are already on this network',
      'failedLoadNetworks': 'Failed to load networks: {e}',
      'failedCreateNetwork': 'Failed to create network: {e}',
      'failedConnect': 'Failed to connect: {e}',
      'failedDisconnect': 'Failed to disconnect: {e}',
      'filesTitle': 'Files',
      'filesSubtitle': 'Browse and manage server files',
      'loadingFiles': 'Loading files...',
      'folderEmpty': 'Folder is empty',
      'uploadOrCreateHint': 'Upload files or create a new folder.',
      'newFolder': 'New Folder',
      'newFile': 'New File',
      'startTyping': 'Start typing...',
      'uploadFile': 'Upload File',
      'folder': 'Folder',
      'parentDirectory': 'Parent directory',
      'rootDirectory': 'Root directory',
      'gridView': 'Grid view',
      'listView': 'List view',
      'deleteFileTitle': 'Delete?',
      'deleteFileBody': '"{name}" will be permanently deleted.',
      'deleteFolderBody':
          '"{name}" and everything inside it will be permanently deleted.',
      'deleteImageBody':
          '"{name}" will be deleted. If still used by a container, Docker may refuse.',
      'deleteNetworkBody':
          '"{name}" will be deleted. If a container is still connected, Docker may refuse.',
      'savedTo': 'Saved to: {path}',
      'failedReadFile': 'Failed to read file: {e}',
      'failedCreateFolder': 'Failed to create folder: {e}',
      'failedOpenFolder': 'Failed to open folder: {e}',
      'failedDownload': 'Failed to download: {e}',
      'failedUpload': 'Failed to upload: {e}',
      'failedRename': 'Failed to rename: {e}',
      'uploadSuccess': '"{name}" uploaded successfully',
      'noComposeStacks': 'No running Compose stacks on this server',
      'stopStackTitle': 'Stop Stack (Down)?',
      'stopStackBody':
          'All containers in stack "{name}" will be stopped & removed (named volumes stay safe unless you run down -v manually).',
      'down': 'Down',
      'editContents': 'Edit contents',
      'openFileLocation': 'Open file location',
      'failedLoadStacks':
          'Failed to load stacks. Ensure the docker compose plugin is installed.\n\n{e}',
      'logsFor': 'Logs — {name}',
      'logsEmpty': '(empty, no output yet)',
      'logsEmptyShort': '(empty)',
      'showingLastLines': 'Showing last {n} lines',
      'loadMore': 'Load more',
      'failedLoadLogs': 'Failed to load logs: {e}',
      'failedSave': 'Failed to save: {e}',
      'ipAlreadyRegistered': 'IP already registered',
      'hostAlreadyUsed':
          'Host {host} is already used by server "{name}". Update that server with the new credentials?',
      'continueAnyway': 'Continue anyway',
      'connectAndSave': 'Connect & Save',
      'password': 'Password',
      'pullExact': 'Pull this name',
      'pullExactHint':
          'No search results. You can still pull the name you typed.',
      'entrypoint': 'Entrypoint',
      'envVars': 'Environment Variables',
      'osLabel': 'OS',
      'execTerminal': 'Exec Terminal',
      'download': 'Download',
      'dockerLabel': 'Docker',
      'fileLabel': 'File',
      'privateKey': 'Private Key',
      'privateKeyPem': 'Private Key (PEM)',
      'passphraseOptional': 'Passphrase (optional)',
      'hostIp': 'Host / IP',
      'port': 'Port',
      'username': 'Username',
      'serverName': 'Server name',
      'connecting': 'Connecting',
      'failedConnectCreds':
          'Connection failed. Check host, credentials, or fingerprint.',
      'general': 'General',
      'configuration': 'Configuration',
      'host': 'Host',
      'verifyHost': 'Verify Host',
      'fingerprintChanged': 'Fingerprint Changed!',
      'fingerprintChangedBody':
          'This server fingerprint differs from the one saved before. This may mean the server was reinstalled, OR a man-in-the-middle attack. Do not continue if unsure.',
      'fingerprintNewBody':
          'This host has never been trusted. Match the fingerprint below with the one on the server before continuing.',
      'trustAndContinue': 'Trust & Continue',
      'keyType': 'Key type',
      'liveStats': 'Live Stats',
      'statsTitle': 'Stats: {name}',
      'waitingStats':
          'Waiting for first stats data...\n(if the container is not running, there is no data)',
      'statsLiveHint': 'Updates live while this screen is open.',
      'failedLoadStats': 'Failed to load stats: {e}',
      'failedLoadDetails': 'Failed to load details: {e}',
      'memory': 'Memory',
      'networkIo': 'Network I/O',
      'blockIo': 'Block I/O',
      'pids': 'PIDs',
      'ports': 'Ports',
      'notPublished': '(not published)',
      'state': 'State',
      'image': 'Image',
      'command': 'Command',
      'created': 'Created',
      'startedAt': 'Started At',
      'restartCount': 'Restart Count',
      'restartPolicy': 'Restart Policy',
      'networkMode': 'Network Mode',
      'workingDir': 'Working Dir',
      'mounts': 'Mounts',
      'networks': 'Networks',
      'source': 'Source',
      'architecture': 'Architecture',
      'config': 'Config',
      'container': 'Container',
      'terminalHostTitle': 'Host Terminal — {name}',
      'sessionEnded': '\r\n[session ended]\r\n',
      'failedOpenTerminal': 'Failed to open terminal: {e}',
      'failedOpenHostTerminal': 'Failed to open host terminal: {e}',
      'featureComingSoon': 'Not available yet, coming in a future update.',
      'networkFeatureDesc':
          'Manage docker networks (list/create/connect/remove)',
      'filesFeatureDesc': 'Browse/upload/download files on the server via SFTP',
      'createContainer': 'Create Container',
      'optionalAuto': 'Optional — auto if empty',
      'network': 'Network',
      'portMapping': 'Port mapping',
      'hostPort': 'Host',
      'containerPort': 'Container',
      'protocol': 'Proto',
      'volumeMounts': 'Volume mounts',
      'hostPath': 'Host path / volume',
      'containerPath': 'Container path',
      'readOnly': 'Read-only',
      'autoRemove': 'Auto-remove (--rm)',
      'autoRemoveHint': 'Remove container when it exits',
      'privileged': 'Privileged mode',
      'failedCreateContainer': 'Failed to create container: {e}',
    },
    'id': {
      'appTitle': 'Docker Manager',
      'cancel': 'Batal',
      'delete': 'Hapus',
      'save': 'Simpan',
      'create': 'Buat',
      'update': 'Update',
      'retry': 'Coba lagi',
      'tryAgain': 'Coba Lagi',
      'refresh': 'Refresh',
      'loading': 'Memuat...',
      'errorGeneric': 'Terjadi kesalahan',
      'back': 'Kembali',
      'more': 'Lainnya',
      'moreActions': 'Aksi lainnya',
      'name': 'Nama',
      'status': 'Status',
      'size': 'Ukuran',
      'unknown': 'Tidak diketahui',
      'confirm': 'Konfirmasi',
      'close': 'Tutup',
      'search': 'Cari',
      'optional': 'Opsional',
      'requiredField': 'Wajib diisi',
      'failed': 'Gagal: {e}',
      'saved': 'Tersimpan',
      'resetDefault': 'Reset default',
      'connect': 'Hubungkan',
      'disconnect': 'Putuskan',
      'start': 'Start',
      'stop': 'Stop',
      'restart': 'Restart',
      'pause': 'Pause',
      'unpause': 'Unpause',
      'rename': 'Rename',
      'inspect': 'Inspect',
      'logs': 'Logs',
      'exec': 'Exec',
      'stats': 'Stats',
      'pull': 'Pull',
      'remove': 'Hapus',
      'edit': 'Edit',
      'online': 'Online',
      'offline': 'Offline',
      'running': 'Running',
      'paused': 'Paused',
      'restarting': 'Restarting',
      'checking': 'Memeriksa...',
      'reachable': 'Reachable',
      'unreachable': 'Unreachable',
      'settings': 'Pengaturan',
      'settingsSubtitle': 'Preferensi aplikasi',
      'appearance': 'Tampilan',
      'theme': 'Tema',
      'themeSystem': 'Otomatis',
      'themeLight': 'Terang',
      'themeDark': 'Gelap',
      'language': 'Bahasa',
      'langAuto': 'Otomatis',
      'langId': 'Indonesia',
      'langEn': 'English',
      'langZh': '中文',
      'langJa': '日本語',
      'dockerConfig': 'Konfigurasi Docker',
      'dockerCliPath': 'Path Docker CLI',
      'dockerCliPathHint':
          'Binary docker di server remote (contoh: docker atau /usr/bin/docker)',
      'logLines': 'Baris log default',
      'logLinesDesc':
          'Jumlah baris terakhir saat membuka logs container/compose',
      'lines100': '100 baris',
      'lines500': '500 baris',
      'lines1000': '1000 baris',
      'dashboard': 'Dashboard',
      'addServer': 'Tambah server',
      'addServerTitle': 'Tambah Server',
      'editServerTitle': 'Edit Server',
      'editServer': 'Edit Server',
      'reconnect': 'Reconnect',
      'saveChanges': 'Simpan Perubahan',
      'noServersTitle': 'Belum ada server tersimpan',
      'noServersBody':
          'Tambah server pertama kamu buat mulai monitoring Docker.',
      'servers': 'Server',
      'serversOnline': '{n} dari {total} server online',
      'deleteServerTitle': 'Hapus Server?',
      'deleteServerBody':
          'Server "{name}" akan dihapus beserta kredensial tersimpannya. Tindakan ini tidak bisa dibatalkan.',
      'justNow': 'baru saja',
      'minutesAgo': '{n} menit lalu',
      'hoursAgo': '{n} jam lalu',
      'daysAgo': '{n} hari lalu',
      'neverConnected': 'Belum pernah connect — tap buat connect pertama kali',
      'lastData': 'Data terakhir: {time}',
      'containersRunning': '{running} / {total} running',
      'cpu': 'CPU',
      'ram': 'RAM',
      'disk': 'Disk',
      'live': 'Live',
      'msLatency': '{n} ms',
      'tabContainers': 'Containers',
      'tabImages': 'Images',
      'tabVolumes': 'Volumes',
      'tabNetwork': 'Network',
      'tabFiles': 'Files',
      'serverLabel': 'Server',
      'resources': 'RESOURCES',
      'terminalHost': 'Terminal Host',
      'compose': 'Compose',
      'composeStacks': 'Compose Stacks',
      'dockerCompose': 'Docker Compose',
      'dockerManager': 'Docker Manager',
      'containersTitle': 'Containers',
      'containersSubtitle': 'Kelola container Docker',
      'loadingContainers': 'Memuat containers...',
      'noContainersFound': 'Tidak ada container',
      'createContainerHint': 'Buat container atau deploy Compose stack.',
      'deleteContainerTitle': 'Hapus Container?',
      'deleteContainerBody': '"{name}" akan dihapus permanen dari server.',
      'renameContainer': 'Rename Container',
      'containerName': 'Nama container',
      'newName': 'Nama baru',
      'failedLoadContainers': 'Gagal ambil daftar container: {e}',
      'imagesTitle': 'Images',
      'imagesSubtitle': 'Kelola image Docker',
      'loadingImages': 'Memuat images...',
      'noImagesFound': 'Tidak ada image',
      'pullImageHint': 'Pull image dari registry untuk mulai.',
      'pullImage': 'Pull Image',
      'imageName': 'Nama image',
      'imageDetails': 'Detail Image',
      'failedLoadImages': 'Gagal ambil daftar image: {e}',
      'failedPull': 'Gagal pull: {e}',
      'failedInspect': 'Gagal inspect: {e}',
      'volumesTitle': 'Volumes',
      'volumesSubtitle': 'Kelola storage persistent Docker',
      'loadingVolumes': 'Memuat volumes...',
      'noVolumesFound': 'Tidak ada volume',
      'createVolumeHint': 'Buat volume untuk menyimpan data container.',
      'createVolume': 'Buat Volume',
      'volumeName': 'Nama volume',
      'deleteVolumeTitle': 'Hapus Volume?',
      'deleteVolumeBody':
          '"{name}" akan dihapus. Kalau masih dipakai container, penghapusan akan gagal.',
      'failedLoadVolumes': 'Gagal ambil daftar volume: {e}',
      'failedCreateVolume': 'Gagal buat volume: {e}',
      'failedDelete': 'Gagal hapus: {e}',
      'networkTitle': 'Network',
      'networkSubtitle': 'Kelola network Docker',
      'loadingNetworks': 'Memuat networks...',
      'noNetworksFound': 'Tidak ada network',
      'createNetworkHint': 'Buat network untuk mulai.',
      'createNetwork': 'Buat Network',
      'networkName': 'Nama network',
      'driver': 'Driver',
      'scope': 'Scope',
      'builtInNetwork': 'Network bawaan Docker',
      'deleteNetworkTitle': 'Hapus Network?',
      'connectContainer': 'Connect Container',
      'connectContainerHint':
          'Hubungkan container yang berjalan ke network ini.',
      'connectedContainers': 'Container terhubung',
      'containersOnNetwork': 'Container yang terhubung ke network ini',
      'noConnectedContainers': 'Tidak ada container terhubung',
      'allContainersConnected':
          'Semua container yang berjalan sudah terhubung ke network ini',
      'failedLoadNetworks': 'Gagal ambil daftar network: {e}',
      'failedCreateNetwork': 'Gagal buat network: {e}',
      'failedConnect': 'Gagal connect: {e}',
      'failedDisconnect': 'Gagal disconnect: {e}',
      'filesTitle': 'Files',
      'filesSubtitle': 'Jelajahi dan kelola file server',
      'loadingFiles': 'Memuat file...',
      'folderEmpty': 'Folder kosong',
      'uploadOrCreateHint': 'Upload file atau buat folder baru.',
      'newFolder': 'Folder Baru',
      'newFile': 'File Baru',
      'startTyping': 'Mulai mengetik...',
      'uploadFile': 'Upload File',
      'folder': 'Folder',
      'parentDirectory': 'Direktori induk',
      'rootDirectory': 'Direktori root',
      'gridView': 'Tampilan grid',
      'listView': 'Tampilan list',
      'deleteFileTitle': 'Hapus?',
      'deleteFileBody': '"{name}" akan dihapus permanen.',
      'deleteFolderBody':
          '"{name}" beserta semua isinya akan dihapus permanen.',
      'deleteImageBody':
          '"{name}" akan dihapus. Kalau masih dipakai container, Docker bisa menolak.',
      'deleteNetworkBody':
          '"{name}" akan dihapus. Kalau masih ada container yang terhubung, Docker bisa menolak.',
      'savedTo': 'Tersimpan di: {path}',
      'failedReadFile': 'Gagal baca file: {e}',
      'failedCreateFolder': 'Gagal buat folder: {e}',
      'failedOpenFolder': 'Gagal buka folder: {e}',
      'failedDownload': 'Gagal download: {e}',
      'failedUpload': 'Gagal upload: {e}',
      'failedRename': 'Gagal rename: {e}',
      'uploadSuccess': '"{name}" berhasil diupload',
      'noComposeStacks': 'Belum ada compose stack yang berjalan di server ini',
      'stopStackTitle': 'Stop Stack (Down)?',
      'stopStackBody':
          'Semua container di stack "{name}" bakal dimatikan & dihapus (volume named tetap aman, kecuali kamu jalanin down -v manual).',
      'down': 'Down',
      'editContents': 'Edit Isinya',
      'openFileLocation': 'Buka Lokasi File',
      'failedLoadStacks':
          'Gagal ambil daftar stack. Pastikan plugin docker compose terpasang di server.\n\n{e}',
      'logsFor': 'Logs — {name}',
      'logsEmpty': '(kosong, belum ada output)',
      'logsEmptyShort': '(kosong)',
      'showingLastLines': 'Menampilkan {n} baris terakhir',
      'loadMore': 'Muat lebih banyak',
      'failedLoadLogs': 'Gagal ambil logs: {e}',
      'failedSave': 'Gagal simpan: {e}',
      'ipAlreadyRegistered': 'IP Sudah Terdaftar',
      'hostAlreadyUsed':
          'Host {host} udah kepake sama server "{name}". Update data & kredensial server itu dengan yang baru kamu isi?',
      'continueAnyway': 'Tetap Lanjut',
      'connectAndSave': 'Connect & Simpan',
      'password': 'Password',
      'pullExact': 'Pull nama ini',
      'pullExactHint':
          'Tidak ada hasil pencarian. Tetap bisa pull nama yang kamu ketik.',
      'entrypoint': 'Entrypoint',
      'envVars': 'Environment Variables',
      'osLabel': 'OS',
      'execTerminal': 'Exec Terminal',
      'download': 'Download',
      'dockerLabel': 'Docker',
      'fileLabel': 'File',
      'privateKey': 'Private Key',
      'privateKeyPem': 'Private Key (PEM)',
      'passphraseOptional': 'Passphrase (opsional)',
      'hostIp': 'Host / IP',
      'port': 'Port',
      'username': 'Username',
      'serverName': 'Nama server',
      'connecting': 'Connecting',
      'failedConnectCreds':
          'Gagal connect. Cek host, kredensial, atau fingerprint.',
      'general': 'Umum',
      'configuration': 'Konfigurasi',
      'host': 'Host',
      'verifyHost': 'Verifikasi Host',
      'fingerprintChanged': 'Fingerprint Berubah!',
      'fingerprintChangedBody':
          'Fingerprint server ini beda dari yang tersimpan sebelumnya. Ini bisa berarti server di-reinstall, ATAU ada serangan man-in-the-middle. Jangan lanjut kalau tidak yakin.',
      'fingerprintNewBody':
          'Host ini belum pernah dipercaya. Cocokkan fingerprint di bawah dengan yang ada di server sebelum lanjut.',
      'trustAndContinue': 'Percaya & Lanjut',
      'keyType': 'Key type',
      'liveStats': 'Live Stats',
      'statsTitle': 'Stats: {name}',
      'waitingStats':
          'Menunggu data stats pertama...\n(kalau container gak berjalan, gak ada data)',
      'statsLiveHint': 'Update live selama layar ini dibuka.',
      'failedLoadStats': 'Gagal ambil stats: {e}',
      'failedLoadDetails': 'Gagal ambil detail: {e}',
      'memory': 'Memory',
      'networkIo': 'Network I/O',
      'blockIo': 'Block I/O',
      'pids': 'PIDs',
      'ports': 'Ports',
      'notPublished': '(tidak di-publish)',
      'state': 'State',
      'image': 'Image',
      'command': 'Command',
      'created': 'Created',
      'startedAt': 'Started At',
      'restartCount': 'Restart Count',
      'restartPolicy': 'Restart Policy',
      'networkMode': 'Network Mode',
      'workingDir': 'Working Dir',
      'mounts': 'Mounts',
      'networks': 'Networks',
      'source': 'Source',
      'architecture': 'Architecture',
      'config': 'Config',
      'container': 'Container',
      'terminalHostTitle': 'Terminal Host — {name}',
      'sessionEnded': '\r\n[sesi berakhir]\r\n',
      'failedOpenTerminal': 'Gagal buka terminal: {e}',
      'failedOpenHostTerminal': 'Gagal buka terminal host: {e}',
      'featureComingSoon': 'belum tersedia, nyusul di update berikutnya.',
      'networkFeatureDesc':
          'Kelola docker network (list/create/connect/remove)',
      'filesFeatureDesc': 'Browse/upload/download file di server via SFTP',
      'failedSearch': 'Gagal cari: {e}',
      'failedBuild': 'Gagal build: {e}',
      'searchPullImage': 'Cari & Pull',
      'buildImage': 'Build Image',
      'searchImageHint': 'Cari di Docker Hub…',
      'imageTag': 'Tag',
      'useDockerfile': 'Pakai Dockerfile',
      'dockerfileContent': 'Isi Dockerfile',
      'buildContextPath': 'Path context build',
      'searchingImages': 'Mencari…',
      'noSearchResults': 'Tidak ada hasil',
      'buildingImage': 'Sedang build image…',
      'pullingImage': 'Sedang pull image…',
      'stars': 'bintang',
      'official': 'Official',
      'createContainer': 'Buat Container',
      'optionalAuto': 'Opsional — otomatis jika kosong',
      'network': 'Network',
      'portMapping': 'Port mapping',
      'hostPort': 'Host',
      'containerPort': 'Container',
      'protocol': 'Proto',
      'volumeMounts': 'Volume mounts',
      'hostPath': 'Path host / volume',
      'containerPath': 'Path container',
      'readOnly': 'Read-only',
      'autoRemove': 'Auto-remove (--rm)',
      'autoRemoveHint': 'Hapus container saat berhenti',
      'privileged': 'Privileged mode',
      'failedCreateContainer': 'Gagal buat container: {e}',
    },
    'zh': {
      'appTitle': 'Docker Manager',
      'cancel': '取消',
      'delete': '删除',
      'save': '保存',
      'create': '创建',
      'update': '更新',
      'retry': '重试',
      'tryAgain': '再试一次',
      'refresh': '刷新',
      'loading': '加载中...',
      'errorGeneric': '出错了',
      'back': '返回',
      'more': '更多',
      'moreActions': '更多操作',
      'name': '名称',
      'status': '状态',
      'size': '大小',
      'unknown': '未知',
      'confirm': '确认',
      'close': '关闭',
      'search': '搜索',
      'optional': '可选',
      'requiredField': '必填',
      'failed': '失败：{e}',
      'saved': '已保存',
      'resetDefault': '恢复默认',
      'connect': '连接',
      'disconnect': '断开',
      'start': '启动',
      'stop': '停止',
      'restart': '重启',
      'pause': '暂停',
      'unpause': '恢复',
      'rename': '重命名',
      'inspect': '检查',
      'logs': '日志',
      'exec': '执行',
      'stats': '统计',
      'pull': '拉取',
      'remove': '删除',
      'edit': '编辑',
      'online': '在线',
      'offline': '离线',
      'running': '运行中',
      'paused': '已暂停',
      'restarting': '重启中',
      'checking': '检查中...',
      'reachable': '可达',
      'unreachable': '不可达',
      'settings': '设置',
      'settingsSubtitle': '应用偏好',
      'appearance': '外观',
      'theme': '主题',
      'themeSystem': '跟随系统',
      'themeLight': '浅色',
      'themeDark': '深色',
      'language': '语言',
      'langAuto': '自动',
      'langId': 'Indonesia',
      'langEn': 'English',
      'langZh': '中文',
      'langJa': '日本語',
      'dockerConfig': 'Docker 配置',
      'dockerCliPath': 'Docker CLI 路径',
      'dockerCliPathHint': '远程服务器上的 docker 可执行文件',
      'logLines': '默认日志行数',
      'logLinesDesc': '打开日志时获取的末尾行数',
      'lines100': '100 行',
      'lines500': '500 行',
      'lines1000': '1000 行',
      'dashboard': '仪表盘',
      'addServer': '添加服务器',
      'addServerTitle': '添加服务器',
      'editServerTitle': '编辑服务器',
      'editServer': '编辑服务器',
      'reconnect': '重新连接',
      'saveChanges': '保存更改',
      'noServersTitle': '还没有保存服务器',
      'noServersBody': '添加第一台服务器以开始监控 Docker。',
      'servers': '服务器',
      'serversOnline': '{n} / {total} 台服务器在线',
      'deleteServerTitle': '删除服务器？',
      'deleteServerBody': '服务器 “{name}” 及其凭证将被删除。此操作无法撤销。',
      'justNow': '刚刚',
      'minutesAgo': '{n} 分钟前',
      'hoursAgo': '{n} 小时前',
      'daysAgo': '{n} 天前',
      'neverConnected': '尚未连接 — 点按以连接',
      'lastData': '最近数据：{time}',
      'containersRunning': '{running} / {total} 运行中',
      'cpu': 'CPU',
      'ram': '内存',
      'disk': '磁盘',
      'live': '实时',
      'msLatency': '{n} 毫秒',
      'tabContainers': '容器',
      'tabImages': '镜像',
      'tabVolumes': '卷',
      'tabNetwork': '网络',
      'tabFiles': '文件',
      'serverLabel': '服务器',
      'resources': '资源',
      'terminalHost': '主机终端',
      'compose': 'Compose',
      'composeStacks': 'Compose 堆栈',
      'dockerCompose': 'Docker Compose',
      'dockerManager': 'Docker Manager',
      'containersTitle': '容器',
      'containersSubtitle': '管理 Docker 容器',
      'loadingContainers': '正在加载容器...',
      'noContainersFound': '未找到容器',
      'createContainerHint': '创建容器或部署 Compose 堆栈。',
      'deleteContainerTitle': '删除容器？',
      'deleteContainerBody': '“{name}” 将从服务器永久删除。',
      'renameContainer': '重命名容器',
      'containerName': '容器名称',
      'newName': '新名称',
      'failedLoadContainers': '加载容器失败：{e}',
      'imagesTitle': '镜像',
      'imagesSubtitle': '管理 Docker 镜像',
      'loadingImages': '正在加载镜像...',
      'noImagesFound': '未找到镜像',
      'pullImageHint': '从仓库拉取镜像以开始。',
      'pullImage': '拉取镜像',
      'searchPullImage': '搜索并拉取',
      'buildImage': '构建镜像',
      'searchImageHint': '搜索 Docker Hub…',
      'imageTag': '标签',
      'useDockerfile': '使用 Dockerfile',
      'dockerfileContent': 'Dockerfile 内容',
      'buildContextPath': '构建上下文路径',
      'searchingImages': '搜索中…',
      'noSearchResults': '无结果',
      'buildingImage': '正在构建镜像…',
      'pullingImage': '正在拉取镜像…',
      'failedSearch': '搜索失败：{e}',
      'failedBuild': '构建失败：{e}',
      'stars': '星',
      'official': '官方',
      'imageName': '镜像名称',
      'imageDetails': '镜像详情',
      'failedLoadImages': '加载镜像失败：{e}',
      'failedPull': '拉取失败：{e}',
      'failedInspect': '检查失败：{e}',
      'volumesTitle': '卷',
      'volumesSubtitle': '管理 Docker 持久存储',
      'loadingVolumes': '正在加载卷...',
      'noVolumesFound': '未找到卷',
      'createVolumeHint': '创建卷以持久化容器数据。',
      'createVolume': '创建卷',
      'volumeName': '卷名称',
      'deleteVolumeTitle': '删除卷？',
      'deleteVolumeBody': '“{name}” 将被删除。若仍被容器使用，删除可能失败。',
      'failedLoadVolumes': '加载卷失败：{e}',
      'failedCreateVolume': '创建卷失败：{e}',
      'failedDelete': '删除失败：{e}',
      'networkTitle': '网络',
      'networkSubtitle': '管理 Docker 网络',
      'loadingNetworks': '正在加载网络...',
      'noNetworksFound': '未找到网络',
      'createNetworkHint': '创建网络以开始。',
      'createNetwork': '创建网络',
      'networkName': '网络名称',
      'driver': '驱动',
      'scope': '范围',
      'builtInNetwork': '内置 Docker 网络',
      'deleteNetworkTitle': '删除网络？',
      'connectContainer': '连接容器',
      'connectContainerHint': '将运行中的容器连接到此网络。',
      'connectedContainers': '已连接的容器',
      'containersOnNetwork': '连接到此网络的容器',
      'noConnectedContainers': '没有已连接的容器',
      'allContainersConnected': '所有运行中的容器已连接到此网络',
      'failedLoadNetworks': '加载网络失败：{e}',
      'failedCreateNetwork': '创建网络失败：{e}',
      'failedConnect': '连接失败：{e}',
      'failedDisconnect': '断开失败：{e}',
      'filesTitle': '文件',
      'filesSubtitle': '浏览和管理服务器文件',
      'loadingFiles': '正在加载文件...',
      'folderEmpty': '文件夹为空',
      'uploadOrCreateHint': '上传文件或创建新文件夹。',
      'newFolder': '新建文件夹',
      'newFile': '新建文件',
      'startTyping': '开始输入...',
      'uploadFile': '上传文件',
      'folder': '文件夹',
      'parentDirectory': '上级目录',
      'rootDirectory': '根目录',
      'gridView': '网格视图',
      'listView': '列表视图',
      'deleteFileTitle': '删除？',
      'deleteFileBody': '“{name}” 将被永久删除。',
      'deleteFolderBody': '“{name}” 及其所有内容将被永久删除。',
      'deleteImageBody': '“{name}” 将被删除。若仍被容器使用，Docker 可能会拒绝。',
      'deleteNetworkBody': '“{name}” 将被删除。若仍有容器连接，Docker 可能会拒绝。',
      'savedTo': '已保存到：{path}',
      'failedReadFile': '读取文件失败：{e}',
      'failedCreateFolder': '创建文件夹失败：{e}',
      'failedOpenFolder': '打开文件夹失败：{e}',
      'failedDownload': '下载失败：{e}',
      'failedUpload': '上传失败：{e}',
      'failedRename': '重命名失败：{e}',
      'uploadSuccess': '“{name}” 上传成功',
      'noComposeStacks': '此服务器上没有运行中的 Compose 堆栈',
      'stopStackTitle': '停止堆栈 (Down)？',
      'stopStackBody': '堆栈 “{name}” 中的所有容器将被停止并删除（命名卷仍安全，除非手动 down -v）。',
      'down': 'Down',
      'editContents': '编辑内容',
      'openFileLocation': '打开文件位置',
      'failedLoadStacks': '加载堆栈失败。请确保已安装 docker compose 插件。\n\n{e}',
      'logsFor': '日志 — {name}',
      'logsEmpty': '（空，尚无输出）',
      'logsEmptyShort': '（空）',
      'showingLastLines': '显示最后 {n} 行',
      'loadMore': '加载更多',
      'failedLoadLogs': '加载日志失败：{e}',
      'failedSave': '保存失败：{e}',
      'ipAlreadyRegistered': 'IP 已注册',
      'hostAlreadyUsed': '主机 {host} 已被服务器 “{name}” 使用。要用新凭证更新该服务器吗？',
      'continueAnyway': '仍然继续',
      'connectAndSave': '连接并保存',
      'password': '密码',
      'pullExact': '拉取此名称',
      'pullExactHint': '没有搜索结果。仍可拉取你输入的名称。',
      'entrypoint': '入口点',
      'envVars': '环境变量',
      'osLabel': '操作系统',
      'execTerminal': '执行终端',
      'download': '下载',
      'dockerLabel': 'Docker',
      'fileLabel': '文件',
      'privateKey': '私钥',
      'privateKeyPem': '私钥 (PEM)',
      'passphraseOptional': '密码短语（可选）',
      'hostIp': '主机 / IP',
      'port': '端口',
      'username': '用户名',
      'serverName': '服务器名称',
      'connecting': '连接中',
      'failedConnectCreds': '连接失败。请检查主机、凭证或指纹。',
      'general': '常规',
      'configuration': '配置',
      'host': '主机',
      'verifyHost': '验证主机',
      'fingerprintChanged': '指纹已更改！',
      'fingerprintChangedBody': '此服务器指纹与之前保存的不同。可能是服务器重装，或中间人攻击。不确定时请勿继续。',
      'fingerprintNewBody': '此主机尚未受信任。继续前请与服务器上的指纹核对。',
      'trustAndContinue': '信任并继续',
      'keyType': '密钥类型',
      'liveStats': '实时统计',
      'statsTitle': '统计：{name}',
      'waitingStats': '等待首个统计数据...\n（容器未运行则无数据）',
      'statsLiveHint': '此屏幕打开时实时更新。',
      'failedLoadStats': '加载统计失败：{e}',
      'failedLoadDetails': '加载详情失败：{e}',
      'memory': '内存',
      'networkIo': '网络 I/O',
      'blockIo': '块 I/O',
      'pids': 'PIDs',
      'ports': '端口',
      'notPublished': '（未发布）',
      'state': '状态',
      'image': '镜像',
      'command': '命令',
      'created': '创建时间',
      'startedAt': '启动时间',
      'restartCount': '重启次数',
      'restartPolicy': '重启策略',
      'networkMode': '网络模式',
      'workingDir': '工作目录',
      'mounts': '挂载',
      'networks': '网络',
      'source': '源',
      'architecture': '架构',
      'config': '配置',
      'container': '容器',
      'terminalHostTitle': '主机终端 — {name}',
      'sessionEnded': '\r\n[会话已结束]\r\n',
      'failedOpenTerminal': '打开终端失败：{e}',
      'failedOpenHostTerminal': '打开主机终端失败：{e}',
      'featureComingSoon': '暂未提供，将在后续更新中推出。',
      'networkFeatureDesc': '管理 docker 网络（列表/创建/连接/删除）',
      'filesFeatureDesc': '通过 SFTP 浏览/上传/下载服务器文件',
      'createContainer': '创建容器',
      'optionalAuto': '可选 — 留空则自动',
      'network': '网络',
      'portMapping': '端口映射',
      'hostPort': '主机',
      'containerPort': '容器',
      'protocol': '协议',
      'volumeMounts': '卷挂载',
      'hostPath': '主机路径 / 卷',
      'containerPath': '容器路径',
      'readOnly': '只读',
      'autoRemove': '自动删除 (--rm)',
      'autoRemoveHint': '退出时删除容器',
      'privileged': '特权模式',
      'failedCreateContainer': '创建容器失败：{e}',
    },
    'ja': {
      'appTitle': 'Docker Manager',
      'cancel': 'キャンセル',
      'delete': '削除',
      'save': '保存',
      'create': '作成',
      'update': '更新',
      'retry': '再試行',
      'tryAgain': '再試行',
      'refresh': '更新',
      'loading': '読み込み中...',
      'errorGeneric': 'エラーが発生しました',
      'back': '戻る',
      'more': 'その他',
      'moreActions': 'その他の操作',
      'name': '名前',
      'status': 'ステータス',
      'size': 'サイズ',
      'unknown': '不明',
      'confirm': '確認',
      'close': '閉じる',
      'search': '検索',
      'optional': '任意',
      'requiredField': '必須',
      'failed': '失敗: {e}',
      'saved': '保存しました',
      'resetDefault': 'デフォルトに戻す',
      'connect': '接続',
      'disconnect': '切断',
      'start': '開始',
      'stop': '停止',
      'restart': '再起動',
      'pause': '一時停止',
      'unpause': '再開',
      'rename': '名前変更',
      'inspect': '検査',
      'logs': 'ログ',
      'exec': '実行',
      'stats': '統計',
      'pull': 'プル',
      'remove': '削除',
      'edit': '編集',
      'online': 'オンライン',
      'offline': 'オフライン',
      'running': '実行中',
      'paused': '一時停止',
      'restarting': '再起動中',
      'checking': '確認中...',
      'reachable': '到達可能',
      'unreachable': '到達不可',
      'settings': '設定',
      'settingsSubtitle': 'アプリの設定',
      'appearance': '外観',
      'theme': 'テーマ',
      'themeSystem': 'システム',
      'themeLight': 'ライト',
      'themeDark': 'ダーク',
      'language': '言語',
      'langAuto': '自動',
      'langId': 'Indonesia',
      'langEn': 'English',
      'langZh': '中文',
      'langJa': '日本語',
      'dockerConfig': 'Docker 設定',
      'dockerCliPath': 'Docker CLI パス',
      'dockerCliPathHint': 'リモートサーバー上の docker バイナリ',
      'logLines': 'デフォルトのログ行数',
      'logLinesDesc': 'ログを開くときに取得する末尾行数',
      'lines100': '100 行',
      'lines500': '500 行',
      'lines1000': '1000 行',
      'dashboard': 'ダッシュボード',
      'addServer': 'サーバーを追加',
      'addServerTitle': 'サーバーを追加',
      'editServerTitle': 'サーバーを編集',
      'editServer': 'サーバーを編集',
      'reconnect': '再接続',
      'saveChanges': '変更を保存',
      'noServersTitle': 'サーバーがまだありません',
      'noServersBody': '最初のサーバーを追加して Docker の監視を始めましょう。',
      'servers': 'サーバー',
      'serversOnline': '{n} / {total} 台のサーバーがオンライン',
      'deleteServerTitle': 'サーバーを削除しますか？',
      'deleteServerBody': 'サーバー「{name}」と資格情報が削除されます。この操作は取り消せません。',
      'justNow': 'たった今',
      'minutesAgo': '{n} 分前',
      'hoursAgo': '{n} 時間前',
      'daysAgo': '{n} 日前',
      'neverConnected': '未接続 — タップして接続',
      'lastData': '最終データ: {time}',
      'containersRunning': '{running} / {total} 実行中',
      'cpu': 'CPU',
      'ram': 'RAM',
      'disk': 'ディスク',
      'live': 'ライブ',
      'msLatency': '{n} ms',
      'tabContainers': 'コンテナ',
      'tabImages': 'イメージ',
      'tabVolumes': 'ボリューム',
      'tabNetwork': 'ネットワーク',
      'tabFiles': 'ファイル',
      'serverLabel': 'サーバー',
      'resources': 'リソース',
      'terminalHost': 'ホストターミナル',
      'compose': 'Compose',
      'composeStacks': 'Compose スタック',
      'dockerCompose': 'Docker Compose',
      'dockerManager': 'Docker Manager',
      'containersTitle': 'コンテナ',
      'containersSubtitle': 'Docker コンテナを管理',
      'loadingContainers': 'コンテナを読み込み中...',
      'noContainersFound': 'コンテナがありません',
      'createContainerHint': 'コンテナを作成するか Compose スタックをデプロイしてください。',
      'deleteContainerTitle': 'コンテナを削除しますか？',
      'deleteContainerBody': '「{name}」はサーバーから完全に削除されます。',
      'renameContainer': 'コンテナ名の変更',
      'containerName': 'コンテナ名',
      'newName': '新しい名前',
      'failedLoadContainers': 'コンテナの取得に失敗: {e}',
      'imagesTitle': 'イメージ',
      'imagesSubtitle': 'Docker イメージを管理',
      'loadingImages': 'イメージを読み込み中...',
      'noImagesFound': 'イメージがありません',
      'pullImageHint': 'レジストリからイメージをプルして開始します。',
      'pullImage': 'イメージをプル',
      'searchPullImage': '検索してプル',
      'buildImage': 'イメージをビルド',
      'searchImageHint': 'Docker Hub を検索…',
      'imageTag': 'タグ',
      'useDockerfile': 'Dockerfile を使う',
      'dockerfileContent': 'Dockerfile の内容',
      'buildContextPath': 'ビルドコンテキストパス',
      'searchingImages': '検索中…',
      'noSearchResults': '結果なし',
      'buildingImage': 'イメージをビルド中…',
      'pullingImage': 'イメージをプル中…',
      'failedSearch': '検索に失敗: {e}',
      'failedBuild': 'ビルドに失敗: {e}',
      'stars': 'スター',
      'official': '公式',
      'imageName': 'イメージ名',
      'imageDetails': 'イメージ詳細',
      'failedLoadImages': 'イメージの取得に失敗: {e}',
      'failedPull': 'プルに失敗: {e}',
      'failedInspect': '検査に失敗: {e}',
      'volumesTitle': 'ボリューム',
      'volumesSubtitle': 'Docker の永続ストレージを管理',
      'loadingVolumes': 'ボリュームを読み込み中...',
      'noVolumesFound': 'ボリュームがありません',
      'createVolumeHint': 'コンテナデータを永続化するボリュームを作成します。',
      'createVolume': 'ボリュームを作成',
      'volumeName': 'ボリューム名',
      'deleteVolumeTitle': 'ボリュームを削除しますか？',
      'deleteVolumeBody': '「{name}」は削除されます。コンテナが使用中の場合、削除に失敗することがあります。',
      'failedLoadVolumes': 'ボリュームの取得に失敗: {e}',
      'failedCreateVolume': 'ボリュームの作成に失敗: {e}',
      'failedDelete': '削除に失敗: {e}',
      'networkTitle': 'ネットワーク',
      'networkSubtitle': 'Docker ネットワークを管理',
      'loadingNetworks': 'ネットワークを読み込み中...',
      'noNetworksFound': 'ネットワークがありません',
      'createNetworkHint': 'ネットワークを作成して開始します。',
      'createNetwork': 'ネットワークを作成',
      'networkName': 'ネットワーク名',
      'driver': 'ドライバー',
      'scope': 'スコープ',
      'builtInNetwork': '組み込み Docker ネットワーク',
      'deleteNetworkTitle': 'ネットワークを削除しますか？',
      'connectContainer': 'コンテナを接続',
      'connectContainerHint': '実行中のコンテナをこのネットワークに接続します。',
      'connectedContainers': '接続中のコンテナ',
      'containersOnNetwork': 'このネットワークに接続されたコンテナ',
      'noConnectedContainers': '接続されたコンテナはありません',
      'allContainersConnected': '実行中のコンテナはすべてこのネットワークに接続済みです',
      'failedLoadNetworks': 'ネットワークの取得に失敗: {e}',
      'failedCreateNetwork': 'ネットワークの作成に失敗: {e}',
      'failedConnect': '接続に失敗: {e}',
      'failedDisconnect': '切断に失敗: {e}',
      'filesTitle': 'ファイル',
      'filesSubtitle': 'サーバーファイルを閲覧・管理',
      'loadingFiles': 'ファイルを読み込み中...',
      'folderEmpty': 'フォルダは空です',
      'uploadOrCreateHint': 'ファイルをアップロードするか新しいフォルダを作成してください。',
      'newFolder': '新しいフォルダ',
      'newFile': '新しいファイル',
      'startTyping': '入力を開始...',
      'uploadFile': 'ファイルをアップロード',
      'folder': 'フォルダ',
      'parentDirectory': '親ディレクトリ',
      'rootDirectory': 'ルートディレクトリ',
      'gridView': 'グリッド表示',
      'listView': 'リスト表示',
      'deleteFileTitle': '削除しますか？',
      'deleteFileBody': '「{name}」は完全に削除されます。',
      'deleteFolderBody': '「{name}」とその中身がすべて完全に削除されます。',
      'deleteImageBody': '「{name}」は削除されます。コンテナで使用中の場合、Docker が拒否することがあります。',
      'deleteNetworkBody': '「{name}」は削除されます。接続中のコンテナがある場合、Docker が拒否することがあります。',
      'savedTo': '保存先: {path}',
      'failedReadFile': 'ファイルの読み取りに失敗: {e}',
      'failedCreateFolder': 'フォルダの作成に失敗: {e}',
      'failedOpenFolder': 'フォルダを開けません: {e}',
      'failedDownload': 'ダウンロードに失敗: {e}',
      'failedUpload': 'アップロードに失敗: {e}',
      'failedRename': '名前の変更に失敗: {e}',
      'uploadSuccess': '「{name}」のアップロードが完了しました',
      'noComposeStacks': 'このサーバーで実行中の Compose スタックはありません',
      'stopStackTitle': 'スタックを停止 (Down) しますか？',
      'stopStackBody':
          'スタック「{name}」内の全コンテナが停止・削除されます（名前付きボリュームは down -v しない限り安全です）。',
      'down': 'Down',
      'editContents': '内容を編集',
      'openFileLocation': 'ファイルの場所を開く',
      'failedLoadStacks':
          'スタックの取得に失敗。docker compose プラグインがインストールされているか確認してください。\n\n{e}',
      'logsFor': 'ログ — {name}',
      'logsEmpty': '（空、出力なし）',
      'logsEmptyShort': '（空）',
      'showingLastLines': '末尾 {n} 行を表示',
      'loadMore': 'さらに読み込む',
      'failedLoadLogs': 'ログの取得に失敗: {e}',
      'failedSave': '保存に失敗: {e}',
      'ipAlreadyRegistered': 'IP は既に登録されています',
      'hostAlreadyUsed': 'ホスト {host} はサーバー「{name}」で使用中です。新しい資格情報で更新しますか？',
      'continueAnyway': '続行する',
      'connectAndSave': '接続して保存',
      'password': 'パスワード',
      'pullExact': 'この名前をプル',
      'pullExactHint': '検索結果なし。入力した名前でプルできます。',
      'entrypoint': 'エントリポイント',
      'envVars': '環境変数',
      'osLabel': 'OS',
      'execTerminal': 'Exec ターミナル',
      'download': 'ダウンロード',
      'dockerLabel': 'Docker',
      'fileLabel': 'ファイル',
      'privateKey': '秘密鍵',
      'privateKeyPem': '秘密鍵 (PEM)',
      'passphraseOptional': 'パスフレーズ（任意）',
      'hostIp': 'ホスト / IP',
      'port': 'ポート',
      'username': 'ユーザー名',
      'serverName': 'サーバー名',
      'connecting': '接続中',
      'failedConnectCreds': '接続に失敗。ホスト、資格情報、指紋を確認してください。',
      'general': '一般',
      'configuration': '設定',
      'host': 'ホスト',
      'verifyHost': 'ホストの検証',
      'fingerprintChanged': '指紋が変更されました！',
      'fingerprintChangedBody':
          'このサーバーの指紋は保存済みのものと異なります。再インストールか、中間者攻撃の可能性があります。確信がない場合は続行しないでください。',
      'fingerprintNewBody': 'このホストは未信頼です。続行前に以下の指紋をサーバー側と照合してください。',
      'trustAndContinue': '信頼して続行',
      'keyType': 'キータイプ',
      'liveStats': 'ライブ統計',
      'statsTitle': '統計: {name}',
      'waitingStats': '最初の統計データを待機中...\n（コンテナが停止中の場合データはありません）',
      'statsLiveHint': 'この画面を開いている間リアルタイム更新されます。',
      'failedLoadStats': '統計の取得に失敗: {e}',
      'failedLoadDetails': '詳細の取得に失敗: {e}',
      'memory': 'メモリ',
      'networkIo': 'ネットワーク I/O',
      'blockIo': 'ブロック I/O',
      'pids': 'PIDs',
      'ports': 'ポート',
      'notPublished': '（未公開）',
      'state': '状態',
      'image': 'イメージ',
      'command': 'コマンド',
      'created': '作成日時',
      'startedAt': '開始時刻',
      'restartCount': '再起動回数',
      'restartPolicy': '再起動ポリシー',
      'networkMode': 'ネットワークモード',
      'workingDir': '作業ディレクトリ',
      'mounts': 'マウント',
      'networks': 'ネットワーク',
      'source': 'ソース',
      'architecture': 'アーキテクチャ',
      'config': '設定',
      'container': 'コンテナ',
      'terminalHostTitle': 'ホストターミナル — {name}',
      'sessionEnded': '\r\n[セッション終了]\r\n',
      'failedOpenTerminal': 'ターミナルを開けません: {e}',
      'failedOpenHostTerminal': 'ホストターミナルを開けません: {e}',
      'featureComingSoon': 'まだ利用できません。今後のアップデートで提供予定です。',
      'networkFeatureDesc': 'docker ネットワークの管理（一覧/作成/接続/削除）',
      'filesFeatureDesc': 'SFTP でサーバー上のファイルを閲覧/アップロード/ダウンロード',
      'createContainer': 'コンテナを作成',
      'optionalAuto': '任意 — 空なら自動',
      'network': 'ネットワーク',
      'portMapping': 'ポートマッピング',
      'hostPort': 'ホスト',
      'containerPort': 'コンテナ',
      'protocol': 'プロトコル',
      'volumeMounts': 'ボリュームマウント',
      'hostPath': 'ホストパス / ボリューム',
      'containerPath': 'コンテナパス',
      'readOnly': '読み取り専用',
      'autoRemove': '自動削除 (--rm)',
      'autoRemoveHint': '終了時にコンテナを削除',
      'privileged': '特権モード',
      'failedCreateContainer': 'コンテナ作成に失敗: {e}',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'id', 'zh', 'ja'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
