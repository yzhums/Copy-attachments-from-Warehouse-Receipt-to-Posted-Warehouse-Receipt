pageextension 50111 WarehouseReceiptExt extends "Warehouse Receipts"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(Database::"Warehouse Receipt Header"),
                              "No." = FIELD("No.");
            }
        }
    }
}

pageextension 50113 PostedWhseReceiptExt extends "Posted Whse. Receipt List"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = CONST(Database::"Posted Whse. Receipt Header"),
                              "No." = FIELD("No.");
            }
        }
    }
}

enumextension 50111 AttachmentDocumentType extends "Attachment Document Type"
{
    value(50010; "Warehouse Receipt")
    {
        Caption = 'Warehouse Receipt';
    }
}

codeunit 50113 DocumentAttachment
{
    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Factbox", 'OnBeforeDrillDown', '', false, false)]
    local procedure OnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef);
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        case DocumentAttachment."Table ID" of
            DATABASE::"Warehouse Receipt Header":
                begin
                    RecRef.Open(DATABASE::"Warehouse Receipt Header");
                    if WarehouseReceiptHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(WarehouseReceiptHeader);
                end;
            Database::"Posted Whse. Receipt Header":
                begin
                    RecRef.Open(DATABASE::"Posted Whse. Receipt Header");
                    if PostedWhseReceiptHeader.Get(DocumentAttachment."No.") then
                        RecRef.GetTable(PostedWhseReceiptHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Document Attachment Details", 'OnAfterOpenForRecRef', '', false, false)]
    local procedure OnAfterOpenForRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef);
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        case RecRef.Number of
            DATABASE::"Warehouse Receipt Header":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.SetRange("No.", RecNo);
                end;
            DATABASE::"Posted Whse. Receipt Header":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.SetRange("No.", RecNo);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    local procedure OnAfterInitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        case RecRef.Number of
            DATABASE::"Warehouse Receipt Header":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.Validate("No.", RecNo);
                end;
            DATABASE::"Posted Whse. Receipt Header":
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value;
                    DocumentAttachment.Validate("No.", RecNo);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnAfterPostedWhseRcptHeaderInsert, '', false, false)]
    local procedure CopyAttachments(var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; WarehouseReceiptHeader: Record "Warehouse Receipt Header");
    var
        FromDocumentAttachment: Record "Document Attachment";
        ToDocumentAttachment: Record "Document Attachment";
    begin
        FromDocumentAttachment.SetRange("Table ID", Database::"Warehouse Receipt Header");
        if FromDocumentAttachment.IsEmpty() then
            exit;

        FromDocumentAttachment.SetRange("No.", WarehouseReceiptHeader."No.");
        if FromDocumentAttachment.FindSet() then
            repeat
                Clear(ToDocumentAttachment);
                ToDocumentAttachment.Init();
                ToDocumentAttachment.TransferFields(FromDocumentAttachment);
                ToDocumentAttachment.Validate("Table ID", Database::"Posted Whse. Receipt Header");
                ToDocumentAttachment.Validate("No.", PostedWhseReceiptHeader."No.");
                ToDocumentAttachment.Validate("Document Type", Enum::"Attachment Document Type"::"Warehouse Receipt");
                if not ToDocumentAttachment.Insert(true) then;
                ToDocumentAttachment."Attached Date" := FromDocumentAttachment."Attached Date";
                ToDocumentAttachment.Modify();
            until FromDocumentAttachment.Next() = 0;
    end;
}
