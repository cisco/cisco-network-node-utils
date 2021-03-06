# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: ems.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "IOSXRExtensibleManagabilityService.ConfigGetArgs" do
    optional :ReqId, :int64, 1
    optional :yangpathjson, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.ConfigGetReply" do
    optional :ResReqId, :int64, 1
    optional :yangjson, :string, 2
    optional :errors, :string, 3
  end
  add_message "IOSXRExtensibleManagabilityService.GetOperArgs" do
    optional :ReqId, :int64, 1
    optional :yangpathjson, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.GetOperReply" do
    optional :ResReqId, :int64, 1
    optional :yangjson, :string, 2
    optional :errors, :string, 3
  end
  add_message "IOSXRExtensibleManagabilityService.ConfigArgs" do
    optional :ReqId, :int64, 1
    optional :yangjson, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.ConfigReply" do
    optional :ResReqId, :int64, 1
    optional :errors, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.CliConfigArgs" do
    optional :ReqId, :int64, 1
    optional :cli, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.CliConfigReply" do
    optional :ResReqId, :int64, 1
    optional :errors, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.CommitReplaceArgs" do
    optional :ReqId, :int64, 1
    optional :cli, :string, 2
    optional :yangjson, :string, 3
  end
  add_message "IOSXRExtensibleManagabilityService.CommitReplaceReply" do
    optional :ResReqId, :int64, 1
    optional :errors, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.CommitMsg" do
    optional :label, :string, 1
    optional :comment, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.CommitArgs" do
    optional :msg, :message, 1, "IOSXRExtensibleManagabilityService.CommitMsg"
    optional :ReqId, :int64, 2
  end
  add_message "IOSXRExtensibleManagabilityService.CommitReply" do
    optional :result, :enum, 1, "IOSXRExtensibleManagabilityService.CommitResult"
    optional :ResReqId, :int64, 2
    optional :errors, :string, 3
  end
  add_message "IOSXRExtensibleManagabilityService.DiscardChangesArgs" do
    optional :ReqId, :int64, 1
  end
  add_message "IOSXRExtensibleManagabilityService.DiscardChangesReply" do
    optional :ResReqId, :int64, 1
    optional :errors, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.ShowCmdArgs" do
    optional :ReqId, :int64, 1
    optional :cli, :string, 2
  end
  add_message "IOSXRExtensibleManagabilityService.ShowCmdTextReply" do
    optional :ResReqId, :int64, 1
    optional :output, :string, 2
    optional :errors, :string, 3
  end
  add_message "IOSXRExtensibleManagabilityService.ShowCmdJSONReply" do
    optional :ResReqId, :int64, 1
    optional :jsonoutput, :string, 2
    optional :errors, :string, 3
  end
  add_enum "IOSXRExtensibleManagabilityService.CommitResult" do
    value :CHANGE, 0
    value :NO_CHANGE, 1
    value :FAIL, 2
  end
end

module IOSXRExtensibleManagabilityService
  ConfigGetArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.ConfigGetArgs").msgclass
  ConfigGetReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.ConfigGetReply").msgclass
  GetOperArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.GetOperArgs").msgclass
  GetOperReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.GetOperReply").msgclass
  ConfigArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.ConfigArgs").msgclass
  ConfigReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.ConfigReply").msgclass
  CliConfigArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CliConfigArgs").msgclass
  CliConfigReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CliConfigReply").msgclass
  CommitReplaceArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CommitReplaceArgs").msgclass
  CommitReplaceReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CommitReplaceReply").msgclass
  CommitMsg = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CommitMsg").msgclass
  CommitArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CommitArgs").msgclass
  CommitReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CommitReply").msgclass
  DiscardChangesArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.DiscardChangesArgs").msgclass
  DiscardChangesReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.DiscardChangesReply").msgclass
  ShowCmdArgs = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.ShowCmdArgs").msgclass
  ShowCmdTextReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.ShowCmdTextReply").msgclass
  ShowCmdJSONReply = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.ShowCmdJSONReply").msgclass
  CommitResult = Google::Protobuf::DescriptorPool.generated_pool.lookup("IOSXRExtensibleManagabilityService.CommitResult").enummodule
end
