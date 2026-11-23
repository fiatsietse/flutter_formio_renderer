/// Bundled representative Form.io JSON schemas for the example application.
class ExampleFixtures {
  static const Map<String, String> all = {
    '01_basic_registration': basicRegistration,
    '02_conditional_wizard': conditionalWizard,
    '03_nested_and_repeating': nestedAndRepeating,
    '04_calculated_totals': calculatedTotals,
    '05_dependent_dropdowns': dependentDropdowns,
    '06_existing_submission': existingSubmission,
    '07_unsupported_and_cyclic': unsupportedAndCyclic,
    '08_file_upload_and_signature': fileUploadAndSignature,
  };

  static const String basicRegistration = r'''
{
  "display": "form",
  "title": "User Registration",
  "name": "userRegistration",
  "components": [
    {
      "type": "textfield",
      "key": "firstName",
      "label": "First Name",
      "placeholder": "Enter first name",
      "validate": {
        "required": true,
        "minLength": 2
      }
    },
    {
      "type": "textfield",
      "key": "lastName",
      "label": "Last Name",
      "placeholder": "Enter last name",
      "validate": {
        "required": true
      }
    },
    {
      "type": "email",
      "key": "email",
      "label": "Email Address",
      "placeholder": "name@example.com",
      "validate": {
        "required": true
      }
    },
    {
      "type": "password",
      "key": "password",
      "label": "Password",
      "placeholder": "Enter password",
      "validate": {
        "required": true,
        "minLength": 6
      }
    },
    {
      "type": "phoneNumber",
      "key": "phone",
      "label": "Phone Number",
      "placeholder": "+1 555-0199"
    },
    {
      "type": "checkbox",
      "key": "terms",
      "label": "I agree to the Terms of Service",
      "validate": {
        "required": true
      }
    },
    {
      "type": "button",
      "key": "submit",
      "label": "Register",
      "action": "submit"
    }
  ],
  "i18n": {
    "en": {
      "User Registration": "User Registration",
      "First Name": "First Name",
      "Last Name": "Last Name",
      "Email Address": "Email Address",
      "Password": "Password",
      "Phone Number": "Phone Number",
      "I agree to the Terms of Service": "I agree to the Terms of Service",
      "Register": "Register",
      "Enter first name": "Enter first name",
      "Enter last name": "Enter last name",
      "Enter password": "Enter password"
    },
    "fr": {
      "User Registration": "Inscription Utilisateur",
      "First Name": "Prénom",
      "Last Name": "Nom de famille",
      "Email Address": "Adresse e-mail",
      "Password": "Mot de passe",
      "Phone Number": "Numéro de téléphone",
      "I agree to the Terms of Service": "J'accepte les conditions d'utilisation",
      "Register": "S'inscrire",
      "Enter first name": "Entrez votre prénom",
      "Enter last name": "Entrez votre nom",
      "Enter password": "Entrez votre mot de passe"
    }
  }
}

''';

  static const String conditionalWizard = r'''
{
  "display": "wizard",
  "title": "Application Wizard",
  "name": "applicationWizard",
  "components": [
    {
      "type": "panel",
      "key": "page1",
      "title": "Personal Details",
      "components": [
        {
          "type": "textfield",
          "key": "fullName",
          "label": "Full Name",
          "validate": {
            "required": true
          }
        },
        {
          "type": "checkbox",
          "key": "hasSpouse",
          "label": "Do you have a spouse?"
        }
      ]
    },
    {
      "type": "panel",
      "key": "page2",
      "title": "Spouse Details",
      "conditional": {
        "show": true,
        "when": "hasSpouse",
        "eq": "true"
      },
      "components": [
        {
          "type": "textfield",
          "key": "spouseName",
          "label": "Spouse Name",
          "validate": {
            "required": true
          }
        },
        {
          "type": "textfield",
          "key": "spouseOccupation",
          "label": "Spouse Occupation"
        }
      ]
    },
    {
      "type": "panel",
      "key": "page3",
      "title": "Confirmation",
      "components": [
        {
          "type": "textarea",
          "key": "notes",
          "label": "Additional Notes"
        },
        {
          "type": "checkbox",
          "key": "confirm",
          "label": "Confirm Application",
          "validate": {
            "required": true
          }
        }
      ]
    }
  ],
  "i18n": {
    "en": {
      "Personal Details": "Personal Details",
      "Full Name": "Full Name",
      "Do you have a spouse?": "Do you have a spouse?",
      "Spouse Details": "Spouse Details",
      "Spouse Name": "Spouse Name",
      "Spouse Occupation": "Spouse Occupation",
      "Confirmation": "Confirmation",
      "Additional Notes": "Additional Notes",
      "Confirm Application": "Confirm Application"
    },
    "fr": {
      "Personal Details": "Informations personnelles",
      "Full Name": "Nom complet",
      "Do you have a spouse?": "Êtes-vous marié(e) ?",
      "Spouse Details": "Informations du conjoint",
      "Spouse Name": "Nom du conjoint",
      "Spouse Occupation": "Profession du conjoint",
      "Confirmation": "Confirmation",
      "Additional Notes": "Remarques additionnelles",
      "Confirm Application": "Confirmer la demande"
    }
  }
}

''';

  static const String nestedAndRepeating = r'''
{
  "display": "form",
  "title": "Organization Hierarchy",
  "name": "orgHierarchy",
  "components": [
    {
      "type": "container",
      "key": "contactInfo",
      "label": "Contact Information",
      "components": [
        {
          "type": "textfield",
          "key": "city",
          "label": "City"
        },
        {
          "type": "textfield",
          "key": "postalCode",
          "label": "Postal Code"
        }
      ]
    },
    {
      "type": "datagrid",
      "key": "employees",
      "label": "Employees",
      "validate": {
        "minRows": 1,
        "maxRows": 5
      },
      "components": [
        {
          "type": "textfield",
          "key": "name",
          "label": "Employee Name",
          "defaultValue": "New Employee",
          "validate": {
            "required": true
          }
        },
        {
          "type": "number",
          "key": "age",
          "label": "Age",
          "defaultValue": 25
        },
        {
          "type": "textfield",
          "key": "role",
          "label": "Role"
        }
      ]
    },
    {
      "type": "editgrid",
      "key": "assets",
      "label": "Assets",
      "components": [
        {
          "type": "textfield",
          "key": "assetName",
          "label": "Asset Name"
        },
        {
          "type": "number",
          "key": "value",
          "label": "Value"
        }
      ]
    }
  ]
}

''';

  static const String calculatedTotals = r'''
{
  "display": "form",
  "title": "Invoice Calculation",
  "name": "invoiceCalculation",
  "components": [
    {
      "type": "datagrid",
      "key": "items",
      "label": "Invoice Items",
      "components": [
        {
          "type": "textfield",
          "key": "description",
          "label": "Description"
        },
        {
          "type": "number",
          "key": "quantity",
          "label": "Quantity",
          "defaultValue": 1
        },
        {
          "type": "number",
          "key": "unitPrice",
          "label": "Unit Price",
          "defaultValue": 10
        },
        {
          "type": "number",
          "key": "lineTotal",
          "label": "Line Total",
          "calculateValue": {
            "*": [
              { "var": "row.quantity" },
              { "var": "row.unitPrice" }
            ]
          }
        }
      ]
    },
    {
      "type": "number",
      "key": "discount",
      "label": "Discount",
      "defaultValue": 5
    },
    {
      "type": "number",
      "key": "shipping",
      "label": "Shipping Fee",
      "defaultValue": 15
    },
    {
      "type": "number",
      "key": "finalTotal",
      "label": "Final Total",
      "calculateValue": {
        "-": [
          { "+": [{ "var": "data.shipping" }, 100] },
          { "var": "data.discount" }
        ]
      }
    }
  ],
  "i18n": {
    "en": {
      "Invoice Items": "Invoice Items",
      "Description": "Description",
      "Quantity": "Quantity",
      "Unit Price": "Unit Price",
      "Line Total": "Line Total",
      "Discount": "Discount",
      "Shipping Fee": "Shipping Fee",
      "Final Total": "Final Total"
    },
    "fr": {
      "Invoice Items": "Lignes de facturation",
      "Description": "Désignation",
      "Quantity": "Quantité",
      "Unit Price": "Prix unitaire",
      "Line Total": "Sous-total ligne",
      "Discount": "Remise",
      "Shipping Fee": "Frais de livraison",
      "Final Total": "Total final"
    }
  }
}

''';

  static const String dependentDropdowns = r'''
{
  "display": "form",
  "title": "Dependent Locations",
  "name": "dependentLocations",
  "components": [
    {
      "type": "select",
      "key": "country",
      "label": "Country",
      "dataSrc": "values",
      "data": {
        "values": [
          { "label": "United States", "value": "us" },
          { "label": "Canada", "value": "ca" },
          { "label": "France", "value": "fr" }
        ]
      },
      "validate": {
        "required": true
      }
    },
    {
      "type": "select",
      "key": "city",
      "label": "City",
      "dataSrc": "url",
      "data": {
        "url": "/api/cities"
      },
      "valueProperty": "id",
      "template": "<span>{{ item.label }}</span>",
      "validate": {
        "required": true
      }
    }
  ],
  "i18n": {
    "en": {
      "Dependent Locations": "Dependent Locations",
      "Country": "Country",
      "City": "City",
      "United States": "United States",
      "Canada": "Canada",
      "France": "France"
    },
    "fr": {
      "Dependent Locations": "Emplacements géographiques",
      "Country": "Pays",
      "City": "Ville",
      "United States": "États-Unis",
      "Canada": "Canada",
      "France": "France"
    }
  }
}

''';

  static const String existingSubmission = r'''
{
  "display": "form",
  "title": "Edit Existing Profile",
  "name": "editProfile",
  "components": [
    {
      "type": "textfield",
      "key": "username",
      "label": "Username",
      "defaultValue": "default_user",
      "validate": {
        "required": true
      }
    },
    {
      "type": "select",
      "key": "role",
      "label": "Role",
      "defaultValue": "viewer",
      "dataSrc": "values",
      "data": {
        "values": [
          { "label": "Viewer", "value": "viewer" },
          { "label": "Editor", "value": "editor" },
          { "label": "Administrator", "value": "admin" }
        ]
      }
    },
    {
      "type": "checkbox",
      "key": "active",
      "label": "Active Status",
      "defaultValue": false
    },
    {
      "type": "textfield",
      "key": "bio",
      "label": "Biography",
      "defaultValue": "No bio entered yet."
    }
  ]
}

''';

  static const String unsupportedAndCyclic = r'''
{
  "display": "form",
  "title": "Cyclic and Unsupported Features",
  "name": "cyclicAndUnsupported",
  "components": [
    {
      "type": "textfield",
      "key": "fieldA",
      "label": "Field A",
      "logic": [
        {
          "name": "Depend On B",
          "trigger": {
            "type": "simple",
            "simple": {
              "when": "fieldB",
              "eq": "trigger"
            }
          },
          "actions": [
            {
              "name": "Set Value A",
              "type": "value",
              "value": "updated_from_b"
            }
          ]
        }
      ]
    },
    {
      "type": "textfield",
      "key": "fieldB",
      "label": "Field B",
      "logic": [
        {
          "name": "Depend On A",
          "trigger": {
            "type": "simple",
            "simple": {
              "when": "fieldA",
              "eq": "updated_from_b"
            }
          },
          "actions": [
            {
              "name": "Set Value B",
              "type": "value",
              "value": "trigger"
            }
          ]
        }
      ]
    },
    {
      "type": "unknown_future_component",
      "key": "unsupportedRequiredField",
      "label": "Special Plugin Field",
      "validate": {
        "required": true
      }
    }
  ]
}

''';

  static const String fileUploadAndSignature = r'''
{
  "display": "form",
  "title": "Document Upload and Sign",
  "name": "uploadAndSign",
  "components": [
    {
      "type": "file",
      "key": "attachments",
      "label": "Document Attachments",
      "storage": "mock",
      "multiple": true,
      "validate": {
        "required": true
      }
    },
    {
      "type": "signature",
      "key": "signature",
      "label": "Signature",
      "validate": {
        "required": true
      }
    },
    {
      "type": "textfield",
      "key": "signerName",
      "label": "Signer Full Name",
      "validate": {
        "required": true
      }
    }
  ],
  "i18n": {
    "en": {
      "Document Attachments": "Document Attachments",
      "Signature": "Signature",
      "Signer Full Name": "Signer Full Name"
    },
    "fr": {
      "Document Attachments": "Pièces jointes",
      "Signature": "Signature électronique",
      "Signer Full Name": "Nom complet du signataire"
    }
  }
}

''';
}
