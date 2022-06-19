// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRaydiumDAO {
    function balanceOf(address) external view returns (uint256);
}

contract RaydiumDAO {
    address public owner;
    uint256 public nextProposal;
    uint256[] public validTokens;
    IRaydiumDAO raydiumDaoContract;

    constructor(address _token) {
        owner = msg.sender;
        nextProposal = 1;
        raydiumDaoContract = IRaydiumDAO(_token);
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        string title;
        mapping (address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping (uint256 => proposal) public Proposals;

    event proposalCreated(
        uint id,
        string description,
        string title,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );

    /**
        * @dev Creates a new proposal
        * @param _proposalist Address of the proposalist
        * @return True if the user holds Raydium coins otherwise false
    */
    function checkProposalEligibility(address _proposalist) private view returns (bool) {
        if (raydiumDaoContract.balanceOf(_proposalist) > 100) {
            return true;
        }
        return false;
    }

    /**
        * @notice Creates a new proposal
        * @param _title Description of the proposal
        * @param _description Array of addresses that can vote for this proposal
    */
    function createProposal(string memory _title, string memory _description) public {
        require(checkProposalEligibility(msg.sender), "Only Raydium coin holders can put forth Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.title = _title;
        newProposal.deadline = block.number + 100;

        emit proposalCreated(nextProposal, _description, _title, msg.sender);
        nextProposal++;
    }

    /**
        * @notice Vote for a proposal
        * @param _id Id of the proposal
        * @param _vote True for voting for the proposal, false for voting against
    */
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    /**
        * @notice Counts the votes for a proposal and determines if the proposal has passed
        * @param _id The id of the proposal to count votes for
    */
    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    /**
        @notice to add more tokens for accepting liquidity for this contract
        @param _token address of the coin contract
    */
    function addTokenId(uint256 _token) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_token);
    }
}