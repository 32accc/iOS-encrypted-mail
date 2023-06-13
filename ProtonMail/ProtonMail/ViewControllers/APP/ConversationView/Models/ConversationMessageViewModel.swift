class ConversationMessageViewModel {

    var isDraft: Bool {
        message.isDraft
    }

    var isTrashed: Bool {
        message.isTrash
    }

    var isSpam: Bool {
        message.contains(location: .spam)
    }

    private(set) var message: MessageEntity {
        didSet {
            state.collapsedViewModel?.messageHasChanged(message: message)
            state.expandedViewModel?.messageHasChanged(message: message)
        }
    }

    private var weekStart: WeekStart {
        user.userInfo.weekStartValue
    }

    private(set) var state: ConversationMessageState
    private let labelId: LabelID
    private let user: UserManager
    private let messageContentViewModelFactory = SingleMessageContentViewModelFactory()
    private let replacingEmailsMap: [String: EmailEntity]
    private let contactGroups: [ContactGroupVO]
    private let internetStatusProvider: InternetConnectionStatusProvider
    let highlightedKeywords: [String]
    private let goToDraft: (MessageID, OriginalScheduleDate?) -> Void

    init(labelId: LabelID,
         message: MessageEntity,
         user: UserManager,
         replacingEmailsMap: [String: EmailEntity],
         contactGroups: [ContactGroupVO],
         internetStatusProvider: InternetConnectionStatusProvider,
         highlightedKeywords: [String],
         goToDraft: @escaping (MessageID, OriginalScheduleDate?) -> Void
    ) {
        self.labelId = labelId
        self.message = message
        self.user = user
        self.replacingEmailsMap = replacingEmailsMap
        self.contactGroups = contactGroups
        self.internetStatusProvider = internetStatusProvider
        self.goToDraft = goToDraft
        self.highlightedKeywords = highlightedKeywords
        let collapsedViewModel = ConversationCollapsedMessageViewModel(
            message: message,
            weekStart: user.userInfo.weekStartValue,
            replacingEmailsMap: replacingEmailsMap,
            contactGroups: contactGroups
        )
        self.state = .collapsed(viewModel: collapsedViewModel)
    }

    func messageHasChanged(message: MessageEntity) {
        guard self.message != message else {
            return
        }
        self.message = message
    }

    func toggleState() {
        state = state.isExpanded ?
            .collapsed(viewModel: .init(
                message: message,
                weekStart: weekStart,
                replacingEmailsMap: replacingEmailsMap,
                contactGroups: contactGroups
            )) :
            .expanded(viewModel: .init(
                message: message,
                messageContent: singleMessageContentViewModel(for: message)
            ))
    }

    private func singleMessageContentViewModel(
        for message: MessageEntity,
        shouldOpenHistory: Bool = false
    ) -> SingleMessageContentViewModel {
        let context = SingleMessageContentViewContext(
            labelId: labelId,
            message: message,
            viewMode: .conversation
        )
        return messageContentViewModelFactory.createViewModel(
            context: context,
            user: user,
            internetStatusProvider: internetStatusProvider,
            systemUpTime: userCachedStatus,
            highlightedKeywords: highlightedKeywords,
            shouldOpenHistory: shouldOpenHistory,
            goToDraft: goToDraft
        )
    }

}

extension ConversationMessageState {

    var isExpanded: Bool {
        guard case .expanded = self else { return false }
        return true
    }

}
