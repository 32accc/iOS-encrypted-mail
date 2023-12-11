//
//  AttachmentViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreDataModel

final class AttachmentViewModel {
    typealias Dependencies = HasEventRSVP
    & HasFetchAttachmentUseCase
    & HasFetchAttachmentMetadataUseCase
    & HasUserManager

    private(set) var attachments: Set<AttachmentInfo> = [] {
        didSet {
            reloadView?()
            if oldValue != attachments {
                checkAttachmentsForInvitations()
            }
        }
    }
    var reloadView: (() -> Void)?

    var numberOfAttachments: Int {
        attachments.count
    }

    var totalSizeOfAllAttachments: Int {
        let attachmentSizes = attachments.map({ $0.size })
        let totalSize = attachmentSizes.reduce(0) { result, value -> Int in
            return result + value
        }
        return totalSize
    }

    private var invitationProcessingTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func attachmentHasChanged(nonInlineAttachments: [AttachmentInfo], mimeAttachments: [MimeAttachment]) {
        var files: [AttachmentInfo] = nonInlineAttachments
        files.append(contentsOf: mimeAttachments)
        self.attachments = Set(files)
    }

    private func checkAttachmentsForInvitations() {
        guard UserInfo.isEventRSVPEnabled else {
            return
        }

        guard let ics = attachments.first(where: { $0.type == .calendar }) else {
            return
        }

        invitationProcessingTask = Task {
            do {
                let icsData = try await fetchAndDecrypt(ics: ics)
                // propagate this data to the UI once it's implemented
                _ = try await dependencies.eventRSVP.parseData(icsData: icsData)
            } catch {
                PMAssertionFailure(error)
            }
        }
    }

    private func fetchAndDecrypt(ics: AttachmentInfo) async throws -> Data {
        let attachmentMetadata = try await dependencies.fetchAttachmentMetadata.execution(
            params: .init(attachmentID: ics.id)
        )

        let attachment = try await dependencies.fetchAttachment.execute(
            params: .init(
                attachmentID: ics.id,
                attachmentKeyPacket: attachmentMetadata.keyPacket,
                userKeys: dependencies.user.toUserKeys()
            )
        )

        return attachment.data
    }
}
