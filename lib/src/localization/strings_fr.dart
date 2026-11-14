import 'formio_strings.dart';

class FormioStringsFr implements FormioStrings {
  const FormioStringsFr();

  @override
  String get required => '{field} est obligatoire';
  @override
  String get minLength => '{field} doit comporter au moins {min} caractères';
  @override
  String get maxLength => '{field} ne doit pas dépasser {max} caractères';
  @override
  String get min => '{field} doit être supérieur ou égal à {min}';
  @override
  String get max => '{field} ne doit pas dépasser {max}';
  @override
  String get pattern => 'Le format de {field} est invalide';
  @override
  String get email => '{field} doit être une adresse e-mail valide';
  @override
  String get url => '{field} doit être une URL valide';
  @override
  String get phone => '{field} doit être un numéro de téléphone valide';
  @override
  String get minSelected => 'Veuillez sélectionner au moins {min} option(s)';
  @override
  String get maxSelected => 'Veuillez sélectionner au plus {max} option(s)';
  @override
  String get minRows => 'Doit contenir au moins {min} ligne(s)';
  @override
  String get maxRows => 'Ne doit pas dépasser {max} ligne(s)';
  @override
  String get invalidJsonLogic =>
      '{field} ne respecte pas la condition de validation';
  @override
  String get invalidScript => 'La validation de {field} a échoué';

  @override
  String get next => 'Suivant';
  @override
  String get previous => 'Précédent';
  @override
  String get submit => 'Soumettre';
  @override
  String get cancel => 'Annuler';
  @override
  String get reset => 'Réinitialiser';
  @override
  String get page => 'Page';
  @override
  String get ofPage => 'sur';

  @override
  String get addAnother => 'Ajouter une ligne';
  @override
  String get removeRow => 'Supprimer';
  @override
  String get edit => 'Modifier';
  @override
  String get saveRow => 'Enregistrer';
  @override
  String get cancelRow => 'Annuler';
  @override
  String get noRows => 'Aucun élément pour le moment';

  @override
  String get uploadFile => 'Téléverser un fichier';
  @override
  String get dropFile => 'Sélectionnez un fichier ou touchez pour téléverser';
  @override
  String get removeFile => 'Supprimer le fichier';

  @override
  String get signHere => 'Signez ci-dessus';
  @override
  String get clearSignature => 'Effacer';

  @override
  String get selectPlaceholder => 'Sélectionnez une option...';
  @override
  String get unsupportedComponent => 'Composant non supporté : {type}';
  @override
  String get fixErrorsBeforeSubmitting =>
      'Veuillez corriger les erreurs avant de soumettre le formulaire.';
}
